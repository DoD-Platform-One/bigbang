#!/usr/bin/env bash

# exit on error
set -e

#Clear out folder if present
rm -rf cypress-tests/
#Create folder for cypress tests
mkdir -p cypress-tests/

#Cloning core
yq e '. | keys | .[] | ... comments=""' "tests/ci/k3d/values.yaml" | while IFS= read -r package; do
  if [[ "$(yq e ".${package}.enabled" "tests/ci/k3d/values.yaml")" == "true" ]]; then
    #Checking for branch not tag
    if [ "$(yq e ".${package}.git.tag" "chart/values.yaml")" != null ]; then
      echo "Cloning ${package} into cypress-tests"
      git -C cypress-tests/ clone -b $(yq e ".${package}.git.tag" "chart/values.yaml") $(yq e ".${package}.git.repo" "chart/values.yaml")
    else
      echo "Cloning ${package} into cypress-tests"
      git -C cypress-tests/ clone -b $(yq e ".${package}.git.branch" "chart/values.yaml") $(yq e ".${package}.git.repo" "chart/values.yaml")
    fi
  fi
done

#Cloning addons
yq e '.addons | keys | .[] | ... comments=""' "tests/ci/k3d/values.yaml" | while IFS= read -r package; do
  if [ "$(yq e ".addons.${package}.enabled" "tests/ci/k3d/values.yaml")" == "true" ]; then
    #Checking for branch not tag
    if [ "$(yq e ".addons.${package}.git.tag" "chart/values.yaml")" != null ]; then
      echo "Cloning ${package} into cypress-tests"
      git -C cypress-tests/ clone -b $(yq e ".addons.${package}.git.tag" "chart/values.yaml") $(yq e ".addons.${package}.git.repo" "chart/values.yaml")
    else
      echo "Cloning ${package} into cypress-tests"
      git -C cypress-tests/ clone -b $(yq e ".addons.${package}.git.branch" "chart/values.yaml") $(yq e ".addons.${package}.git.repo" "chart/values.yaml")
    fi
  fi
done

#Running Cypress tests
for dir in cypress-tests/*/
do
  if [ -f "${dir}tests/cypress.json" ]; then
    echo "Running cypress tests in ${dir}"
    cypress run --project "${dir}"tests
  fi
done
