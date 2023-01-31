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

if [[ $MULTI_NODE == "true" ]]; then
  echo "Enabling multiple nodes (1 server, 3 agent)"
  yq -i e '.agents |= 3' ${PIPELINE_REPO_DESTINATION}/clusters/k3d/dependencies/k3d/config-no-metrics.yaml
  yq -i e '.agents |= 3' ${PIPELINE_REPO_DESTINATION}/clusters/k3d/dependencies/k3d/config.yaml
fi

if [[ ! -z "$K3D_EXTRA_ARGS_VOLUME" ]]; then
  # Setting the ARGS for k3d in one variable (for some unknown reason) doesn't work.
  ## i.e. ARGS="--volume '/var/run/dir:/var/run/dir:shared:*;agent:*'" fails to create the cluster
  ARGS="--volume "
  ARGS+="$K3D_EXTRA_ARGS_VOLUME"
fi

# Conditionals for BB pipelines: metricsServer label, all-packages label, main pipeline, tag pipeline
# Conditionals for Integration pipelines: metricsServer explicitly enabled in values
# Conditionals for any pipeline: `METRICS_DISABLED` ENV set to "true"
if [[ "${PIPELINE_TYPE}" == "BB" && "${CI_DEPLOY_LABELS[*]}" =~ "metricsServer" ]] || \
   [[ "${PIPELINE_TYPE}" == "BB" && "${CI_DEPLOY_LABELS[*]}" =~ "all-packages" ]] || \
   [[ "${PIPELINE_TYPE}" == "BB" && "${CI_COMMIT_BRANCH}" == "${CI_DEFAULT_BRANCH}" ]] || \
   [[ "${PIPELINE_TYPE}" == "BB" && ! -z "$CI_COMMIT_TAG" ]] || \
   [[ "${PIPELINE_TYPE}" == "INTEGRATION" && "$(yq e ".addons.metricsServer.enabled" ${CI_PROJECT_DIR}/bigbang/values.yaml)" == "true" ]] || \
   [[ $METRICS_DISABLED == "true" ]]; then
  echo "Creating k3d cluster without default metric server"
  k3d cluster create ${CI_JOB_ID} --config ${PIPELINE_REPO_DESTINATION}/clusters/k3d/dependencies/k3d/config-no-metrics.yaml --network ${CI_JOB_ID} ${ARGS}
else
  echo "Creating k3d cluster with default metrics server"
  k3d cluster create ${CI_JOB_ID} --config ${PIPELINE_REPO_DESTINATION}/clusters/k3d/dependencies/k3d/config.yaml --network ${CI_JOB_ID} ${ARGS}
fi
