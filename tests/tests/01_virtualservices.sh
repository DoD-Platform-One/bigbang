#!/usr/bin/env bash

# exit on error
set -e

# Populate /etc/hosts
ip=$(kubectl -n istio-system get service public-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Checking "

hosts=`kubectl get virtualservices -A -o jsonpath="{ .items[*].spec.hosts[*] }"`
for host in $hosts; do
  if [ $host == "keycloak.bigbang.dev" ]; then
    ip_passthrough=$(kubectl -n istio-system get service passthrough-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    echo "$ip_passthrough $host" >> /etc/hosts
  else
    echo "$ip $host" >> /etc/hosts
  fi
  curl -svv https://$host/ > /dev/null
done
