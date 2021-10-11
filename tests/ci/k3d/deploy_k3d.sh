#!/usr/bin/env bash

set -ex
trap 'echo exit at ${0}:${LINENO}, command was: ${BASH_COMMAND} 1>&2' ERR
docker login -u ${DOCKER_USER} -p ${DOCKER_PASSWORD}
# if keycloak label or all packages label add deploy k3d without loadbalancer so metallb can be used
if [[ "${CI_COMMIT_BRANCH}" == "${CI_DEFAULT_BRANCH}" ]] || [[ ! -z "$CI_COMMIT_TAG" ]] || [[ $CI_MERGE_REQUEST_LABELS =~ "keycloak" ||  $CI_MERGE_REQUEST_LABELS =~ "all-packages" ]]; then
  k3d cluster create ${CI_JOB_ID} --config tests/ci/k3d/disable-servicelb-config.yaml --network ${CI_JOB_ID}
else
  k3d cluster create ${CI_JOB_ID} --config tests/ci/k3d/config.yaml --network ${CI_JOB_ID}
fi
