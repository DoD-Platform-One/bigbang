#!/usr/bin/env bash

set -e

## This is an array to instantiate the order of wait conditions
ORDERED_HELMRELEASES="gatekeeper istio-operator istio monitoring eck-operator ek fluent-bit twistlock cluster-auditor authservice argocd gitlab haproxy-sso gitlab-runner minio-operator minio anchore sonarqube mattermost-operator mattermost"

## This is the actual deployed helmrelease objects in the cluster
DEPLOYED_HELMRELEASES=$(kubectl get hr --no-headers -n bigbang | awk '{ print $1}')

printf "Identified the following deployed helmreleases:\n%s" "${DEPLOYED_HELMRELEASES}"

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
  kubectl wait --for=condition=Ready --timeout 600s helmrelease -n bigbang $1;
}

## Function to wait on all statefulsets
function wait_sts() {
   timeElapsed=0
   while true; do
      sts=$(kubectl get sts -A -o jsonpath='{.items[*].status.replicas}' | xargs)
      totalSum=$(echo $sts | awk '{for (i=1; i<=NF; i++) c+=$i} {print c}')
      readySts=$(kubectl get sts -A -o jsonpath='{.items[*].status.readyReplicas}' | xargs)
      readySum=$(echo $readySts | awk '{for (i=1; i<=NF; i++) c+=$i} {print c}')
      if [[ $totalSum -eq $readySum ]]; then
         break
      fi
      sleep 5
      timeElapsed=$(($timeElapsed+5))
      if [[ $timeElapsed -ge 600 ]]; then
         echo "Timed out while waiting for stateful sets to be ready."
         exit 1
      fi
   done
}

## Function to wait on all daemonsets
function wait_daemonset(){
   timeElapsed=0
   while true; do
      dmnset=$(kubectl get daemonset -A -o jsonpath='{.items[*].status.desiredNumberScheduled}' | xargs)
      totalSum=$(echo $dmnset | awk '{for (i=1; i<=NF; i++) c+=$i} {print c}')
      readyDmnset=$(kubectl get daemonset -A -o jsonpath='{.items[*].status.numberReady}' | xargs)
      readySum=$(echo $readyDmnset | awk '{for (i=1; i<=NF; i++) c+=$i} {print c}')
      if [[ $totalSum -eq $readySum ]]; then
         break
      fi
      sleep 5
      timeElapsed=$(($timeElapsed+5))
      if [[ $timeElapsed -ge 600 ]]; then
         echo "Timed out while waiting for daemon sets to be ready."
         exit 1
      fi
   done
}


for package in $ORDERED_HELMRELEASES;
do
  if array_contains DEPLOYED_HELMRELEASES "$package";
  then wait_on "$package"
  else echo "Expected package: $package, but not found in release. Update the array in this script if this package is no longer needed"
  fi
done

kubectl get helmreleases,kustomizations,gitrepositories -A

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
kubectl wait --for=condition=Ready --timeout 300s kustomizations.kustomize.toolkit.fluxcd.io -n bigbang secrets

# In case some helm releases are marked as ready before all objects are live...
echo "Waiting on all deployments, statefulsets, and daemonsets"
kubectl wait --for=condition=available --timeout 600s -A deployment --all > /dev/null
wait_sts
wait_daemonset
