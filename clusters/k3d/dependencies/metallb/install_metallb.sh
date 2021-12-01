#!/usr/bin/env bash

set -e
trap 'echo ❌ exit at ${0}:${LINENO}, command was: ${BASH_COMMAND} 1>&2' ERR
set -x

kubectl create -f ${PIPELINE_REPO_DESTINATION}/clusters/k3d/dependencies/metallb/metallb.yaml
kubectl create -f ${PIPELINE_REPO_DESTINATION}/clusters/k3d/dependencies/metallb/metallb-config.yaml

# Wait for MetalLB to be ready before proceeding
kubectl rollout status daemonset speaker -n metallb-system
kubectl rollout status deployment controller -n metallb-system