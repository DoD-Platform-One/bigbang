#!/usr/bin/env bash

set -e
source ${PIPELINE_REPO_DESTINATION}/library/templates.sh

kubectl create ns metallb-system
kubectl label ns metallb-system app=metallb
kubectl create -n metallb-system secret docker-registry private-registry --docker-server="https://registry1.dso.mil" --docker-username="${REGISTRY1_USER}" --docker-password="${REGISTRY1_PASSWORD}"

kubectl create -f ${PIPELINE_REPO_DESTINATION}/clusters/k3d/dependencies/metallb/metallb.yaml
kubectl create -f ${PIPELINE_REPO_DESTINATION}/clusters/k3d/dependencies/metallb/metallb-config.yaml

# Wait for MetalLB to be ready before proceeding
kubectl rollout status daemonset speaker -n metallb-system
kubectl rollout status deployment controller -n metallb-system