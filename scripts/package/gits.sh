#!/bin/bash
set -ex

mkdir -p repos/

# Clone core
yq e ".*.git.repo | select(. != null) | path | .[-3] " "chart/values.yaml" | while IFS= read -r package; do
  git -C repos/ clone -b $(yq e ".${package}.git.tag" "chart/values.yaml") $(yq e ".${package}.git.repo" "chart/values.yaml")
done

# Clone addons
yq e ".addons.*.git.repo | select(. != null) | path | .[-3]" "chart/values.yaml" | while IFS= read -r package; do
  git -C repos/ clone -b $(yq e ".addons.${package}.git.tag" "chart/values.yaml") $(yq e ".addons.${package}.git.repo" "chart/values.yaml")
done
