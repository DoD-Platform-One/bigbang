#!/bin/bash

set -e

# Wait for components to be ready
for package in $(kubectl get --no-headers helmrelease -n bigbang | awk '{print $1}');
do 
  echo "Waiting on package $package" 
  kubectl wait --for=condition=Ready --timeout 500s helmrelease -n bigbang $package;
done

echo "Waiting on Secrets Kustomization"
kubectl wait --for=condition=Ready --timeout 30s kustomizations.kustomize.toolkit.fluxcd.io -n bigbang secrets