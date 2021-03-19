#!/bin/bash
set -ex

mkdir -p repos/

# "Package" ourselves
# Do it this way on purpose (instead of cp or rsync) to ensure this never includes any unwanted "build" artifacts
git -C repos/ clone -b ${CI_COMMIT_REF_NAME} ${CI_REPOSITORY_URL}

# Clone core
yq e ".*.git.repo | select(. != null) | path | .[-3] " "chart/values.yaml" | while IFS= read -r package; do
  git -C repos/ clone -b $(yq e ".${package}.git.tag" "chart/values.yaml") $(yq e ".${package}.git.repo" "chart/values.yaml")
done

# Clone addons
yq e ".addons.*.git.repo | select(. != null) | path | .[-3]" "chart/values.yaml" | while IFS= read -r package; do
  git -C repos/ clone -b $(yq e ".addons.${package}.git.tag" "chart/values.yaml") $(yq e ".addons.${package}.git.repo" "chart/values.yaml")
done
