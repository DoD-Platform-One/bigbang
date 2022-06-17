#!/usr/bin/env bash

set -e
source ${PIPELINE_REPO_DESTINATION}/library/templates.sh

mkdir -p /cypress/screenshots
chown 1000:1000 /cypress/screenshots
mkdir -p /cypress/videos
chown 1000:1000 /cypress/videos
if [[ $DEBUG_ENABLED == "true" ]]; then
  echo "merge labels = ${CI_MERGE_REQUEST_LABELS[*]}"
  echo "Metrics disabled = $METRICS_DISABLED"
fi

if [[ "${CI_MERGE_REQUEST_LABELS[*]}" =~ "metricsServer" ]] || [[ $METRICS_DISABLED == "true" ]] || [[ "${CI_COMMIT_BRANCH}" == "${CI_DEFAULT_BRANCH}" ]] || [[ ! -z "$CI_COMMIT_TAG" ]] || [[ "${CI_DEPLOY_LABELS[*]}" =~ "all-packages" ]]; then
  echo "Creating k3d cluster without default metric server"
  k3d cluster create ${CI_JOB_ID} --config ${PIPELINE_REPO_DESTINATION}/clusters/k3d/dependencies/k3d/config-no-metrics.yaml --network ${CI_JOB_ID}
else
  echo "Creating k3d cluster with default metrics server"
  k3d cluster create ${CI_JOB_ID} --config ${PIPELINE_REPO_DESTINATION}/clusters/k3d/dependencies/k3d/config.yaml --network ${CI_JOB_ID}
fi
