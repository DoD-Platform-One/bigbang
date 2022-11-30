#!/usr/bin/env bash

set -e
source ${PIPELINE_REPO_DESTINATION}/library/templates.sh

# This function is used to enabled core packages that are not enabled by default (i.e. BETA packages, alternatives, etc)
## Args:
## $1: package label to check
function enable_core_package() {
  local package="$1"
  if [[ "${CI_DEPLOY_LABELS[*]}" =~ "${package}" ]] || [[ "${CI_COMMIT_BRANCH}" == "${CI_DEFAULT_BRANCH}" ]] || [[ ! -z "$CI_COMMIT_TAG" ]] || [[ ${CI_DEPLOY_LABELS[*]} =~ "all-packages" ]]; then
    if [[ "$(yq e ". | has(\"${package}\")" $VALUES_FILE)" == "true" ]]; then
      echo "Enabled ${package}"
      yq e ".${package}.enabled = "true"" $CI_VALUES_FILE > tmpfile && mv tmpfile $CI_VALUES_FILE
    else
      echo "Skipping ${package}: not present on branch"
    fi
  fi
}

if [[ "${PIPELINE_TYPE}" == "BB" ]]; then
  if [[ "${CI_COMMIT_BRANCH}" == "${CI_DEFAULT_BRANCH}" ]] || [[ ! -z "$CI_COMMIT_TAG" ]] || [[ "${CI_DEPLOY_LABELS[*]}" =~ "all-packages" ]]; then
    echo "🌌 all-packages label enabled, or on default branch or tag, enabling all addons"
    yq e ".addons.*.enabled = "true"" $CI_VALUES_FILE > tmpfile && mv tmpfile $CI_VALUES_FILE
  else
    IFS=","
    for package in $CI_DEPLOY_LABELS; do
      if [[ "$(yq e ".addons.${package}.enabled" $CI_VALUES_FILE 2>/dev/null)" == "false" ]]; then
        echo "Identified \"$package\" from labels"
        yq e ".addons.${package}.enabled = "true"" $CI_VALUES_FILE > tmpfile && mv tmpfile $CI_VALUES_FILE
      fi 
    done
  fi

  check_core_packages=("kyverno" "kyvernopolicies" "kyvernoreporter" "tempo" "loki" "promtail")

  for package in "${check_core_packages[@]}"; do
    enable_core_package "${package}"
  done
fi

# Get latest ingress certs and add to test values
curl -sS $CERT_FILE_URL -o cert.yaml
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
