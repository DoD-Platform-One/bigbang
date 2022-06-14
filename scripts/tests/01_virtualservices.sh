#!/usr/bin/env bash

# exit on error
set -e
source ${PIPELINE_REPO_DESTINATION}/library/templates.sh

# Populate /etc/hosts
if [[ "$CI_PIPELINE_SOURCE" == "schedule" ]] && [[ "$CI_COMMIT_BRANCH" == "${CI_DEFAULT_BRANCH}" ]] || [[ "${CI_DEPLOY_LABELS[*]}" =~ "test-ci::infra" ]]; then
  ip_hostname=$(kubectl get svc -n istio-system public-ingressgateway -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")
  ip=$(dig $ip_hostname +search +short | head -1)
else
  ip=$(kubectl -n istio-system get service public-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
fi
echo "Checking "

# for debugging
echo "Show virtualservice:"
kubectl get virtualservice -A

for vs in $(kubectl get virtualservice -A -o go-template='{{range .items}}{{.metadata.name}}{{":"}}{{.metadata.namespace}}{{" "}}{{end}}'); do
  vs_name=$(echo ${vs} | awk -F: '{print $1}')
  vs_namespace=$(echo ${vs} | awk -F: '{print $2}')
  hosts=$(kubectl get virtualservice ${vs_name} -n ${vs_namespace} -o go-template='{{range .spec.hosts}}{{.}}{{" "}}{{end}}')
  gateway=$(kubectl get virtualservice ${vs_name} -n ${vs_namespace} -o jsonpath='{.spec.gateways[0]}' | awk -F/ '{print $2}')
  ingress_gateway=$(kubectl get gateway -n istio-system $gateway -o jsonpath='{.spec.selector.app}')
  external_ip=""
  if [[ "$CI_PIPELINE_SOURCE" == "schedule" ]] && [[ "$CI_COMMIT_BRANCH" == "${CI_DEFAULT_BRANCH}" ]] || [[ "${CI_DEPLOY_LABELS[*]}" =~ "test-ci::infra" ]]; then
    external_hostname=$(kubectl get svc -n istio-system $ingress_gateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    external_ip=$(dig $external_hostname +search +short | head -1)
  else
    external_ip=$(kubectl get svc -n istio-system $ingress_gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  fi
  for host in $hosts; do
    host=$(echo ${host} | xargs)
    # remove any previous entry in /etc/hosts if it exists
    if grep -q "${host}" /etc/hosts; then
      # could not get inline sed to work. Copying and replacing instead
      cat /etc/hosts > etchosts
      sed -i "/${host}/d" etchosts
      cp etchosts /etc/hosts
      sleep 2
    fi

    echo "${external_ip} ${host}" >> /etc/hosts
    
    if [[ $DEBUG_ENABLED == "true" || "$CI_MERGE_REQUEST_TITLE" == *"DEBUG"*  ]]; then
      echo "Verify /etc/hosts entries"
      cat /etc/hosts
    fi
    
    echo "****************************************"
    echo "Begin curl $host"
    echo "****************************************"
    curl -svv https://$host/ > /dev/null
    echo "****************************************"
    echo "End curl $host"
    echo "****************************************"
  done
done
