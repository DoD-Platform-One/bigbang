#!/bin/bash

set -e

## This is an array to instantiate the order of wait conditions
ORDERED_HELMRELEASES="gatekeeper istio-operator istio monitoring eck-operator ek fluent-bit twistlock cluster-auditor"


## This the actual deployed helmrelease objects in the cluster
DEPLOYED_HELMRELEASES=$(kubectl get hr --no-headers -n bigbang | awk '{ print $1}')

## Function to test an array contains an element
## Args:
## $1: array to search
## $2: element to search for
function array_contains() {
    local array="$1[@]"
    local seeking=$2
    local in=1
    for element in ${!array}; do
        if [[ $element == "$seeking" ]]; then
            in=0
            break
        fi
    done
    return $in
}

## Function to wait on helmrelease
## Args:
## $1: package name
function wait_on() {
  echo "Waiting on package $1"
  kubectl wait --for=condition=Ready --timeout 500s helmrelease -n bigbang $1;
}

for package in $ORDERED_HELMRELEASES;
do
  if array_contains DEPLOYED_HELMRELEASES "$package";
  then wait_on "$package"
  else echo "Expected package: $package, but not found in release. Update the array in this script if this package is no longer needed"
  fi
done

for package in $DEPLOYED_HELMRELEASES;
do
  if array_contains ORDERED_HELMRELEASES "$package";
  then echo ""
  else 
    echo "Found package: $package, but not found in this script array. Update the array in this script if this package is always needed"
    wait_on "$package"
  fi
done

echo "Waiting on Secrets Kustomization"
kubectl wait --for=condition=Ready --timeout 30s kustomizations.kustomize.toolkit.fluxcd.io -n bigbang secrets