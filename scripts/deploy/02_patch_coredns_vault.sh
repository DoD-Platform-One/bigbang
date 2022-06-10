#!/usr/bin/env bash

# exit on error
set -e
source ${PIPELINE_REPO_DESTINATION}/library/templates.sh

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

# Only if Vault is deploying
if [[ "${CI_COMMIT_BRANCH}" == "${CI_DEFAULT_BRANCH}" ]] || [[ ! -z "$CI_COMMIT_TAG" ]] || [[ "${CI_DEPLOY_LABELS[*]}" =~ "all-packages" ]] || [[ "${CI_DEPLOY_LABELS[*]}" =~ "vault" ]]; then
  # wait for istio to complete
  echo "Waiting for istio to complete..."
  kubectl wait --for=condition=Ready --timeout 900s helmrelease istio -n bigbang
  # Wait until deployment of passthrough-gateway exists
  timeout 60 bash -c "until kubectl get deployment passthrough-ingressgateway -n istio-system; do sleep 5; done;"
  kubectl rollout status -w deployment passthrough-ingressgateway -n istio-system
  # get passthrough IP
  passthrough_ip=""
  if [[ ${clusterType} == "k3d" ]]; then
    passthrough_ip=$(kubectl get svc -n istio-system passthrough-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  elif [[ ${clusterType} == "rke2" ]]; then
    external_hostname=$(kubectl get svc -n istio-system passthrough-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    timeElapsed=0
    while true; do
        passthrough_ip=$(dig $external_hostname +search +short | head -1)
        if [[ ! -z "$passthrough_ip" ]]; then
          break
        fi
        sleep 5
        timeElapsed=$(($timeElapsed+5))
        if [[ $timeElapsed -ge 300 ]]; then
          echo "❌ Timed out while waiting for passthrough loadbalancer to be ready."
          exit 1
        fi
    done
  fi
  echo "${passthrough_ip} vault.bigbang.dev" >> newhosts

  # Patch CoreDNS and restart pod if Vault is enabled
  echo "Setting up CoreDNS for Vault..."
  hosts=$(cat newhosts) yq e -n '.data.NodeHosts = strenv(hosts)' > patch.yaml
  # For k3d
  if [[ ${clusterType} == "k3d" ]]; then
    if [[ $DEBUG_ENABLED == "true" || "$CI_MERGE_REQUEST_TITLE" == *"DEBUG"*  ]]; then
      echo "Verify coredns configmap NodeHosts before patch:"
      testCoreDnsConfig=$(kubectl get cm coredns -n kube-system -o jsonpath='{.data.NodeHosts}'; echo)
      echo $testCoreDnsConfig
    fi
    echo "Starting coredns configmap patch for k3d cluster"
    cat patch.yaml
    kubectl patch configmap -n kube-system ${coreDnsName} --patch "$(cat patch.yaml)"
    kubectl rollout restart deployment -n kube-system ${coreDnsName}
    kubectl rollout status deployment -n kube-system ${coreDnsName} --timeout=30s
    echo "Verify coredns configmap NodeHosts after patch:"
    testCoreDnsConfig=$(kubectl get cm coredns -n kube-system -o jsonpath='{.data.NodeHosts}'; echo)
    echo $testCoreDnsConfig
    echo "Finished patching k3d coredns for Vault."
  # For rke2
  elif [[ ${clusterType} == "rke2" ]]; then
    if [[ $DEBUG_ENABLED == "true" || "$CI_MERGE_REQUEST_TITLE" == *"DEBUG"*  ]]; then
      echo "Verify coredns configmap NodeHosts before patch:"
      testCoreDnsConfig=$(kubectl get cm ${coreDnsName} -n kube-system -o jsonpath='{.data.NodeHosts}'; echo)
      echo $testCoreDnsConfig
    fi
    echo "Starting coredns configmap patch for rke2 cluster"
    cat patch.yaml
    # Add an entry to the corefile
    sed -i '/prometheus/i \ \ \ \ hosts /etc/coredns/NodeHosts {\n        ttl 60\n        reload 15s\n        fallthrough\n    }' newcorefile
    corefile=$(cat newcorefile) yq e -i '.data.Corefile = strenv(corefile)' patch.yaml
    kubectl patch configmap -n kube-system ${coreDnsName} --patch "$(cat patch.yaml)"
    kubectl patch deployment ${coreDnsName} -n kube-system -p '{"spec":{"template":{"spec":{"volumes":[{"name":"config-volume","configMap":{"items":[{"key":"Corefile","path":"Corefile"},{"key":"NodeHosts","path":"NodeHosts"}],"name":"'${coreDnsName}'"}}]}}}}'
    kubectl rollout status deployment -n kube-system ${coreDnsName} --timeout=120s
    if [[ $DEBUG_ENABLED == "true" || "$CI_MERGE_REQUEST_TITLE" == *"DEBUG"*  ]]; then
      echo "Verify coredns configmap NodeHosts after patch:"
      testCoreDnsConfig=$(kubectl get cm ${coreDnsName} -n kube-system -o jsonpath='{.data.NodeHosts}'; echo)
      echo $testCoreDnsConfig
    fi
    echo "Finished patching rke2 coredns for Vault."
  # Add other distros in future as needed, catchall so tests won't error on this
  else
    echo "No known CoreDNS deployment found, skipping patching."
  fi
else
  echo "Vault is not enabled. No action taken."  
fi
