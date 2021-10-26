#!/bin/bash
set -e
trap 'echo ❌ exit at ${0}:${LINENO}, command was: ${BASH_COMMAND} 1>&2' ERR
set -x

mkdir -p repos/

# "Package" ourselves
# Do it this way on purpose (instead of cp or rsync) to ensure this never includes any unwanted "build" artifacts
git -C repos/ clone -b ${CI_COMMIT_REF_NAME} ${CI_PROJECT_URL}

# Clone core
yq e ".*.git.repo | select(. != null) | path | .[-3] " "${VALUES_FILE}" | while IFS= read -r package; do
  git -C repos/ clone --no-checkout $(yq e ".${package}.git.repo" "${VALUES_FILE}")
done

# Clone addons
yq e ".addons.*.git.repo | select(. != null) | path | .[-3]" "${VALUES_FILE}" | while IFS= read -r package; do
  git -C repos/ clone --no-checkout $(yq e ".addons.${package}.git.repo" "${VALUES_FILE}")
done
