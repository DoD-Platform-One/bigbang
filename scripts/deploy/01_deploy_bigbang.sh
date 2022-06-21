#!/usr/bin/env bash

set -e
source ${PIPELINE_REPO_DESTINATION}/library/templates.sh

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

  # Enable kyverno
  if [[ "${CI_DEPLOY_LABELS[*]}" =~ "kyverno" ]] || [[ "${CI_COMMIT_BRANCH}" == "${CI_DEFAULT_BRANCH}" ]] || [[ ! -z "$CI_COMMIT_TAG" ]] || [[ ${CI_DEPLOY_LABELS[*]} =~ "all-packages" ]]; then
      echo "Enabling kyverno"
      yq e ".kyverno.enabled = "true"" $CI_VALUES_FILE > tmpfile && mv tmpfile $CI_VALUES_FILE
  fi

  # Enable kyverno policies
  if [[ "${CI_DEPLOY_LABELS[*]}" =~ "kyvernopolicies" ]] || [[ "${CI_COMMIT_BRANCH}" == "${CI_DEFAULT_BRANCH}" ]] || [[ ! -z "$CI_COMMIT_TAG" ]] || [[ ${CI_DEPLOY_LABELS[*]} =~ "all-packages" ]]; then
      echo "Enabling kyverno policies"
      yq e ".kyvernopolicies.enabled = "true"" $CI_VALUES_FILE > tmpfile && mv tmpfile $CI_VALUES_FILE
  fi

  # Enable tempo
  if [[ "${CI_DEPLOY_LABELS[*]}" =~ "tempo" ]] || [[ "${CI_COMMIT_BRANCH}" == "${CI_DEFAULT_BRANCH}" ]] || [[ ! -z "$CI_COMMIT_TAG" ]] || [[ ${CI_DEPLOY_LABELS[*]} =~ "all-packages" ]]; then
      echo "Enabling tempo"
      yq e ".tempo.enabled = "true"" $CI_VALUES_FILE > tmpfile && mv tmpfile $CI_VALUES_FILE 
  fi

  #If loki or promtail Labels set, adjust logging engine packages
  if [[ "${CI_DEPLOY_LABELS[*]}" =~ "loki" ]] || [[ "${CI_DEPLOY_LABELS[*]}" =~ "promtail" ]] || [[ "${CI_COMMIT_BRANCH}" == "${CI_DEFAULT_BRANCH}" ]] || [[ ! -z "$CI_COMMIT_TAG" ]] || [[ ${CI_DEPLOY_LABELS[*]} =~ "all-packages" ]]; then
      echo "Enabling promtail and loki"
      yq e ".promtail.enabled = "true"" $CI_VALUES_FILE > tmpfile && mv tmpfile $CI_VALUES_FILE
      yq e ".loki.enabled = "true"" $CI_VALUES_FILE > tmpfile && mv tmpfile $CI_VALUES_FILE 
  fi
fi

# Add ingress certs to test values
yq eval-all 'select(fileIndex == 0) * select(filename == "chart/ingress-certs.yaml")' $CI_VALUES_FILE chart/ingress-certs.yaml > tmpfile && mv tmpfile $CI_VALUES_FILE

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
