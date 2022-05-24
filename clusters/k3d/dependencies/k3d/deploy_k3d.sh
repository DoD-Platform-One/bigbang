#!/usr/bin/env bash

set -e
source ${PIPELINE_REPO_DESTINATION}/library/templates.sh

mkdir -p /cypress/screenshots
chown 1000:1000 /cypress/screenshots
mkdir -p /cypress/videos
chown 1000:1000 /cypress/videos

if [[ $METRICS_DISABLED == "true" ]]; then
  echo "Creating k3d cluster without default metric server"
  k3d cluster create ${CI_JOB_ID} --config ${PIPELINE_REPO_DESTINATION}/clusters/k3d/dependencies/k3d/config-no-metrics.yaml --network ${CI_JOB_ID}
else
  echo "Creating k3d cluster with default metrics server"
  k3d cluster create ${CI_JOB_ID} --config ${PIPELINE_REPO_DESTINATION}/clusters/k3d/dependencies/k3d/config.yaml --network ${CI_JOB_ID}
fi
