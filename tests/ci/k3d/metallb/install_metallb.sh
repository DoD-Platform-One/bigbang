#!/usr/bin/env bash

set -e
trap 'echo ❌ exit at ${0}:${LINENO}, command was: ${BASH_COMMAND} 1>&2' ERR
set -x

if [[ "${CI_COMMIT_BRANCH}" == "${CI_DEFAULT_BRANCH}" ]] || [[ ! -z "$CI_COMMIT_TAG" ]] || [[ $CI_MERGE_REQUEST_LABELS =~ "keycloak" ||  $CI_MERGE_REQUEST_LABELS =~ "all-packages" ]]; then
  kubectl create -f tests/ci/k3d/metallb/metallb.yaml
  kubectl create -f tests/ci/k3d/metallb/metallb-config.yaml
else
 echo "Keycloak not present, Metallb will not be install"
fi
