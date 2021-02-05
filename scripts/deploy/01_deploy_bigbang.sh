#!/usr/bin/env bash

set -ex

# Deploy flux and wait for it to be ready
echo "Installing Flux"
flux --version
flux check --pre

# create flux namespace
kubectl create ns flux-system || true

# delete flux private-registry secret
kubectl delete secret private-registry -n flux-system || true

# create flux private-registry secret
kubectl create secret docker-registry private-registry -n flux-system \
   --docker-server=registry1.dso.mil \
   --docker-username='robot$bigbang' \
   --docker-password=${REGISTRY1_PASSWORD} \
   --docker-email=bigbang@bigbang.dev || true

# install flux
kubectl apply -f ./scripts/deploy/flux.yaml

# wait for flux
flux check

# deploy BigBang using dev sized scaling
echo "Installing BigBang"
helm upgrade -i bigbang chart -n bigbang --create-namespace \
--set registryCredentials[0].username='robot$bigbang' --set registryCredentials[0].password=${REGISTRY1_PASSWORD} \
--set registryCredentials[0].registry=registry1.dso.mil \
-f tests/ci/k3d/values.yaml

# apply secrets kustomization pointing to current branch
echo "Deploying secrets from the ${CI_COMMIT_REF_NAME} branch"
if [[ -z "${CI_COMMIT_TAG}" ]]; then
  cat tests/ci/shared-secrets.yaml | sed 's|master|'$CI_COMMIT_REF_NAME'|g' | kubectl apply -f -
else
  # NOTE: $CI_COMMIT_REF_NAME = $CI_COMMIT_TAG when running on a tagged build
  cat tests/ci/shared-secrets.yaml | sed 's|branch: master|tag: '$CI_COMMIT_REF_NAME'|g' | kubectl apply -f -
fi