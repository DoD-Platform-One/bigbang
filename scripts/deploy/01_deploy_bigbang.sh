#!/usr/bin/env bash

set -e
source ${PIPELINE_REPO_DESTINATION}/library/templates.sh

if [[ "${PIPELINE_TYPE}" == "BB" ]]; then
  # master or tagged release or all-packages label
  if [[ "${CI_COMMIT_BRANCH}" == "${CI_DEFAULT_BRANCH}" ]] || [[ ! -z "$CI_COMMIT_TAG" ]] || [[ "${CI_DEPLOY_LABELS[*]}" =~ "all-packages" ]]; then
    echo "🌌 all-packages label enabled, or on default branch or tag, enabling all addons"
    enable_core
    enable_addons
  else
    IFS=","
    for package in $CI_DEPLOY_LABELS; do
      enable "$package"
    done
  fi
fi

# Get latest ingress certs and add to test values
curl -LsS $CERT_FILE_URL -o cert.yaml
if [[ -f cert.yaml ]]; then
  yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' $CI_VALUES_FILE cert.yaml > tmpfile && mv tmpfile $CI_VALUES_FILE
else
  yq eval-all 'select(fileIndex == 0) * select(filename == "chart/ingress-certs.yaml")' $CI_VALUES_FILE chart/ingress-certs.yaml > tmpfile && mv tmpfile $CI_VALUES_FILE
fi

# Deploy BigBang
if [[ ! -z "$CI_VALUES_OVERRIDES_FILE" ]]; then
    echo "🚀 Installing BigBang with the following configurations:"
    # Merging the the CI values file with the CI overrides values file
    yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' $CI_VALUES_FILE $CI_VALUES_OVERRIDES_FILE
    helm upgrade -i bigbang chart -n bigbang --create-namespace \
      --set registryCredentials[0].username="${REGISTRY1_USER}" \
      --set registryCredentials[0].password="${REGISTRY1_PASSWORD}" \
      --set registryCredentials[0].registry=registry1.dso.mil \
      --set registryCredentials[1].username="${DOCKER_USER}" \
      --set registryCredentials[1].password="${DOCKER_PASSWORD}" \
      --set registryCredentials[1].registry=docker.io \
      -f ${CI_VALUES_FILE} \
      -f ${CI_VALUES_OVERRIDES_FILE}
else 
    echo "🚀 Installing BigBang with the following configurations:"
    cat ${CI_VALUES_FILE}
    helm upgrade -i bigbang chart -n bigbang --create-namespace \
      --set registryCredentials[0].username="${REGISTRY1_USER}" \
      --set registryCredentials[0].password="${REGISTRY1_PASSWORD}" \
      --set registryCredentials[0].registry=registry1.dso.mil \
      --set registryCredentials[1].username="${DOCKER_USER}" \
      --set registryCredentials[1].password="${DOCKER_PASSWORD}" \
      --set registryCredentials[1].registry=docker.io \
      -f ${CI_VALUES_FILE}
fi 
