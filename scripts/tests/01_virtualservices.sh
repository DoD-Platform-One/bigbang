#!/usr/bin/env bash

# exit on error
set -e
source ${PIPELINE_REPO_DESTINATION}/library/templates.sh

# Populate /etc/hosts
if [[ "$CI_PIPELINE_SOURCE" == "schedule" ]] && [[ "$CI_COMMIT_BRANCH" == "master" ]] || [[ "${CI_DEPLOY_LABELS[*]}" =~ "test-ci::infra" ]]; then
  ip_hostname=$(kubectl get svc -n istio-system public-ingressgateway -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")
  ip=$(dig $ip_hostname +search +short | head -1)
else
  ip=$(kubectl -n istio-system get service public-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
fi
echo "Checking "

hosts=`kubectl get virtualservices -A -o jsonpath="{ .items[*].spec.hosts[*] }"`
for host in $hosts; do
  if [ $host == "keycloak.bigbang.dev" ]; then
    if [[ "$CI_PIPELINE_SOURCE" == "schedule" ]] && [[ "$CI_COMMIT_BRANCH" == "master" ]] || [[ "${CI_DEPLOY_LABELS[*]}" =~ "test-ci::infra" ]]; then
      ip_passthrough_hostname=$(kubectl -n istio-system get service passthrough-ingressgateway -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")
      ip_passthrough=$(dig $ip_passthrough_hostname +search +short | head -1)
    else
      ip_passthrough=$(kubectl -n istio-system get service passthrough-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    fi
    echo "$ip_passthrough $host" >> /etc/hosts
  else
    echo "$ip $host" >> /etc/hosts
  fi
  echo "****************************************"
  echo "Begin curl $host"
  echo "****************************************"
  curl -svv https://$host/ > /dev/null
  echo "****************************************"
  echo "End curl $host"
  echo "****************************************"
done
