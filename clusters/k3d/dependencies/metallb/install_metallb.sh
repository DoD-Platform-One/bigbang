#!/usr/bin/env bash

set -e
source ${PIPELINE_REPO_DESTINATION}/library/templates.sh

# Create namespace with expected labels and pull secrets
kubectl create ns metallb-system
kubectl label ns metallb-system app=metallb
kubectl create -n metallb-system secret docker-registry private-registry --docker-server="https://registry1.dso.mil" --docker-username="${REGISTRY1_USER}" --docker-password="${REGISTRY1_PASSWORD}"

# Apply MetalLB CRDs and pods
kubectl create -f ${PIPELINE_REPO_DESTINATION}/clusters/k3d/dependencies/metallb/metallb.yaml

# Wait for controller to be live so that validating webhooks function when we apply the config
echo "Waiting on MetalLB controller/webhook..."
kubectl wait --for=condition=available --timeout 120s -n metallb-system deployment controller

# Apply MetalLB custom resources for configuration
kubectl create -f ${PIPELINE_REPO_DESTINATION}/clusters/k3d/dependencies/metallb/metallb-config.yaml

# Wait for speaker pods to be ready before proceeding
kubectl rollout status daemonset speaker -n metallb-system