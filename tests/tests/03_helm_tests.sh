#!/usr/bin/env bash

# exit on error
set -e
trap 'echo exit at ${0}:${LINENO}, command was: ${BASH_COMMAND} 1>&2' ERR

# Check clusterType and get original CoreDNS config
clusterType="unknown"
coreDnsName="unknown"
touch newhosts
if kubectl get configmap -n kube-system coredns &>/dev/null; then
  clusterType="k3d"
  coreDnsName="coredns"
  kubectl get configmap -n kube-system ${coreDnsName} -o jsonpath='{.data.NodeHosts}' > newhosts
elif kubectl get configmap -n kube-system rke2-coredns-rke2-coredns &>/dev/null; then
  clusterType="rke2"
  coreDnsName="rke2-coredns-rke2-coredns"
  kubectl get configmap -n kube-system ${coreDnsName} -o jsonpath='{.data.Corefile}' > newcorefile
fi

# Safeguard in case configmap doesn't end with newline
if [[ $(tail -c 1 newhosts) != "" ]]; then
  echo "" >> newhosts
fi

# Get each VS hostname + ingress gateway IP and add to newhosts
for vs in $(kubectl get virtualservice -A -o go-template='{{range .items}}{{.metadata.name}}{{":"}}{{.metadata.namespace}}{{" "}}{{end}}'); do
  vs_name=$(echo ${vs} | awk -F: '{print $1}')
  vs_namespace=$(echo ${vs} | awk -F: '{print $2}')
  hosts=$(kubectl get virtualservice ${vs_name} -n ${vs_namespace} -o go-template='{{range .spec.hosts}}{{.}}{{" "}}{{end}}')
  gateway=$(kubectl get virtualservice ${vs_name} -n ${vs_namespace} -o jsonpath='{.spec.gateways[0]}' | awk -F/ '{print $2}')
  ingress_gateway=$(kubectl get gateway -n istio-system $gateway -o jsonpath='{.spec.selector.app}')
  external_ip=""
  if [[ ${clusterType} == "k3d" ]]; then
    external_ip=$(kubectl get svc -n istio-system $ingress_gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  elif [[ ${clusterType} == "rke2" ]]; then
    external_hostname=$(kubectl get svc -n istio-system $ingress_gateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    external_ip=$(dig +short ${external_hostname} | tail -n1)
  fi
  for host in $hosts; do
    host=$(echo ${host} | xargs)
    # Remove previous entry if on upgrade job
    sed -i "/$host/d" newhosts
    echo "${external_ip} ${host}" >> newhosts
  done
done

# Patch CoreDNS and restart pod
echo "Setting up CoreDNS for VS resolution..."
hosts=$(cat newhosts) yq e -n '.data.NodeHosts = strenv(hosts)' > patch.yaml
# For k3d
if [[ ${clusterType} == "k3d" ]]; then
  kubectl patch configmap -n kube-system ${coreDnsName} --patch "$(cat patch.yaml)"
  kubectl rollout restart deployment -n kube-system ${coreDnsName}
  kubectl rollout status deployment -n kube-system ${coreDnsName} --timeout=30s
# For rke2
elif [[ ${clusterType} == "rke2" ]]; then
  # Add an entry to the corefile
  sed -i '/prometheus/i \ \ \ \ hosts /etc/coredns/NodeHosts {\n        ttl 60\n        reload 15s\n        fallthrough\n    }' newcorefile
  corefile=$(cat newcorefile) yq e -i '.data.Corefile = strenv(corefile)' patch.yaml
  kubectl patch configmap -n kube-system ${coreDnsName} --patch "$(cat patch.yaml)"
  kubectl patch deployment ${coreDnsName} -n kube-system -p '{"spec":{"template":{"spec":{"volumes":[{"name":"config-volume","configMap":{"items":[{"key":"Corefile","path":"Corefile"},{"key":"NodeHosts","path":"NodeHosts"}],"name":"'${coreDnsName}'"}}]}}}}'
  kubectl rollout status deployment -n kube-system ${coreDnsName} --timeout=30s
# Add other distros in future as needed, catchall so tests won't error on this
else
  echo "No known CoreDNS deployment found, skipping patching."
fi

# Gather all HRs we should test
installed_helmreleases=$(helm list -n bigbang -o json | jq '.[].name' | tr -d '"' | grep -v "bigbang")
mkdir -p test-artifacts
ERRORS=0

# For each HR, if it has helm tests: run them, capture exit code, output logs, and save cypress artifacts
for hr in $installed_helmreleases; do
  echo "Running helm tests for ${hr}..."
  test_result=$(helm test $hr -n bigbang) && export EXIT_CODE=$? || export EXIT_CODE=$?
  test_result=$(echo "${test_result}" | sed '/NOTES/Q')
  namespace=$(echo "$test_result" | yq eval '."NAMESPACE"' -)
  test_suite=$(echo "$test_result" | yq eval '.["TEST SUITE"]' -)
  if [ ! $test_suite == "None" ]; then
    # Since logs are cluttery, only output when failed
    if [[ ${EXIT_CODE} -ne 0 ]]; then
      echo "❌ One or more tests failed for ${hr}"
      ERRORS=$((ERRORS + 1))
      for pod in $(echo "$test_result" | grep "TEST SUITE" | grep "test" | awk -F: '{print $2}' | xargs); do
        # Only output failed pod logs, not all test pods
        if [[ $(kubectl get pod -n ${namespace} ${pod} -o jsonpath='{.status.phase}' 2>/dev/null | xargs) == "Failed" ]]; then
          echo -e "---\nLogs for ${pod}:\n---"
          kubectl logs --tail=-1 -n ${namespace} ${pod}
        fi
      done
      echo "---"
    else
      echo "✅ All tests sucessful for ${hr}"
    fi

    # Grab script logs to save for the artifacts (don't get cypress because its not text friendly + we have the videos/screenshots)
    for pod in $(echo "$test_result" | grep "TEST SUITE" | grep "test" | awk -F: '{print $2}' | xargs); do
      if [[ ! "$pod" =~ "cypress" ]]; then
        if kubectl get pod -n ${namespace} ${pod} &>/dev/null; then
          mkdir -p test-artifacts/${hr}/scripts
          kubectl logs --tail=-1 -n ${namespace} ${pod} >> test-artifacts/${hr}/scripts/pod-logs.txt
        fi
      fi
    done

    # Always save off the artifacts if they exist
    if kubectl get configmap -n ${namespace} cypress-screenshots &>/dev/null; then
      mkdir -p test-artifacts/${hr}/cypress
      kubectl get configmap -n ${namespace} cypress-screenshots -o jsonpath='{.data.cypress-screenshots\.tar\.gz\.b64}' > cypress-screenshots.tar.gz.b64
      cat cypress-screenshots.tar.gz.b64 | base64 -d > cypress-screenshots.tar.gz
      tar -zxf cypress-screenshots.tar.gz --strip-components=2 -C test-artifacts/${hr}/cypress
      rm -rf cypress-screenshots.tar.gz.b64 cypress-screenshots.tar.gz
      kubectl delete configmap -n ${namespace} cypress-screenshots &>/dev/null
    fi
    if kubectl get configmap -n ${namespace} cypress-videos &>/dev/null; then
      mkdir -p test-artifacts/${hr}/cypress
      kubectl get configmap -n ${namespace} cypress-videos -o jsonpath='{.data.cypress-videos\.tar\.gz\.b64}' > cypress-videos.tar.gz.b64
      cat cypress-videos.tar.gz.b64 | base64 -d > cypress-videos.tar.gz
      tar -zxf cypress-videos.tar.gz --strip-components=2 -C test-artifacts/${hr}/cypress
      rm -rf cypress-videos.tar.gz.b64 cypress-videos.tar.gz
      kubectl delete configmap -n ${namespace} cypress-videos &>/dev/null
    fi
  else
    echo "😞 No tests found for ${hr}"
  fi
done

echo "Finished running all helm tests."

if [ $ERRORS -gt 0 ]; then
  echo "❌ Encountered $ERRORS package(s) with errors while running tests. See output logs for failed test(s) above and artifacts in the job."
  exit 123
else
  echo "✅ All helm tests run successfully."
fi
