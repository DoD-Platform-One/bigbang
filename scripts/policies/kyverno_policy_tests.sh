#!/usr/bin/env bash

set -e

# The CI_PROJECT_NAME variable used in this script is a predefined GitLab CI/CD variable - https://docs.gitlab.com/ee/ci/variables/predefined_variables.html

: "${KYVERNO_POLICIES_DIRECTORY:="/tmp/kyverno-policies"}"
: "${KYVERNO_POLICIES_CHART_DIRECTORY:="${KYVERNO_POLICIES_DIRECTORY}/chart"}"
: "${POLICY_MANIFESTS_DIRECTORY:="/tmp/policy-manifests"}"

CI_VALUES_FILE="$(find tests/test-values.y*ml)"

DEBUG="false"
if [[ $DEBUG_ENABLED == "true" || "$CI_MERGE_REQUEST_TITLE" == *"DEBUG"*  || ${CI_MERGE_REQUEST_LABELS} == *"debug"* ]]; then
  echo "DEBUG_ENABLED is set to true, setting -x in bash"
  set -x
  DEBUG="true"
fi

# Clone the kyverno-policies package repo
# and render the kyverno-policies chart into raw YAML manifests
function get_kyverno_policy_manifests() {
   local kyverno_policies_url="https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/kyverno-policies.git"
   local kyverno_policies_release_name="kyverno-policies"
   local kyverno_policies_namespace="kyverno-policies"

   if ${DEBUG}; then
      git clone "${kyverno_policies_url}" "${KYVERNO_POLICIES_DIRECTORY}"
   else
      git clone "${kyverno_policies_url}" "${KYVERNO_POLICIES_DIRECTORY}" &>/dev/null
   fi

   if ${DEBUG}; then
      echo "Rendering out the kyverno-policies helm chart into raw YAML manifests..."
   fi
   helm template "${kyverno_policies_release_name}" "${KYVERNO_POLICIES_CHART_DIRECTORY}" \
      --set "policies.restrict-image-registries.parameters.allow={registry1.dso.mil,registry.dso.mil}" \
      --namespace="${kyverno_policies_namespace}" \
      --output-dir="${POLICY_MANIFESTS_DIRECTORY}" > /dev/null

   # An array of Kyverno policy file names to iterate over
   POLICY_MANIFESTS=( $(find "${POLICY_MANIFESTS_DIRECTORY}"/kyverno-policies/templates/*.y*ml -type f) )
}

# TODO: Adding the warn annotation to all of the policy manifests
# means that a policy test will never fail a pipeline.
# Ideally we would want to fail a pipeline if a policy test fails;
# this would require us to dynamically grab some data from the policies.
# Namely the "validationFailureAction" field
# If this field is set to "audit", the pipeline shouldn't fail even if the policy test fails (gets the warn annotation)
# If this field is set to "enfore", the pipelines should fail if the policy test fails (does not get the warn annotation)

# Add annotation to Kyverno policies that will
# allow them to return a "warn" status, instead of "fail" status when a policy fails
function add_warn_annotation() {
   local kyverno_warn_annotation="policies.kyverno.io/scored"

   if ${DEBUG}; then
      echo "Adding '${kyverno_warn_annotation}: \"false\"' annotation to Kyverno policy manifests..."
   fi
   for policy_manifest in "${POLICY_MANIFESTS[@]}"
   do
      if [[ "${policy_manifest}" == "${POLICY_MANIFESTS_DIRECTORY}/kyverno-policies/templates/restrict-image-registries.yaml" ]]; then
         if ${DEBUG}; then
            echo "Not adding the warn annotation to ${policy_manifest}..."
            echo "${policy_manifest} policy is enforced and will fail the pipeline if it doesn't pass validation..."
         fi
      else
         yq -i ".metadata.annotations[\"${kyverno_warn_annotation}\"] |= \"false\"" "${policy_manifest}"
      fi
   done
}

# Execute the policies from the kyverno-policies package against Big Bang packages
function global_policy_tests() {
   if ${DEBUG}; then
      echo "Checking for a Helm values file used for CI overrides..."
   fi
   if [[ -f "${CI_VALUES_FILE}" ]]; then
      echo "Executing Kyverno policy tests using the ${CI_VALUES_FILE} file as override values for the ${CI_PROJECT_NAME} chart..."
      helm template "${CI_PROJECT_NAME}" chart/ \
         --namespace="${CI_PROJECT_NAME}" \
         --values="${CI_VALUES_FILE}" \
         | kyverno apply "${POLICY_MANIFESTS_DIRECTORY}" --resource -
      echo -e "⬆️  \e[34mSee the policy test results above (tested using test values)\e[37m ⬆️"
      echo "Executing Kyverno policy tests using the default values for the ${CI_PROJECT_NAME} chart..."
      helm template "${CI_PROJECT_NAME}" chart/ \
         --namespace="${CI_PROJECT_NAME}" \
         | kyverno apply "${POLICY_MANIFESTS_DIRECTORY}" --resource -
      echo -e "⬆️  \e[34mSee the policy test results above (tested using default values)\e[37m ⬆️"
   else
      echo "No Helm values file for CI overrides was found..."
      echo "Executing Kyverno policy tests using the default values for the ${CI_PROJECT_NAME} chart..."
      helm template "${CI_PROJECT_NAME}" chart/ \
         --namespace="${CI_PROJECT_NAME}" \
         | kyverno apply "${POLICY_MANIFESTS_DIRECTORY}" --resource -
      echo -e "⬆️  \e[34mSee the policy test results above (tested using default values)\e[37m ⬆️"
   fi
}

# Execute package-specific kyverno policies if they exist
function package_policy_tests() {
   local policy_directory="tests/policy"
   
   if ${DEBUG}; then
      echo "Checking for a '${policy_directory}' directory with YAML policy manifests in the ${CI_PROJECT_NAME} repository..."
   fi
   if $(find "${policy_directory}"/*.y*ml -type f &>/dev/null); then
      if ${DEBUG}; then
         echo "Found a '${policy_directory}' directory with YAML policy manifests in the ${CI_PROJECT_NAME} repository..."
         echo "Checking for a Helm values file used for CI overrides..."
      fi
      if [[ -f "${CI_VALUES_FILE}" ]]; then
         echo "Executing package-specific Kyverno policy tests using the ${CI_VALUES_FILE} as override values for the ${CI_PROJECT_NAME} chart..."
         helm template "${CI_PROJECT_NAME}" chart/ \
            --namespace="${CI_PROJECT_NAME}" \
            --values="${CI_VALUES_FILE}" \
            | kyverno apply "${policy_directory}" --resource -
      else
         echo "No Helm values file for CI overrides was found..."
         echo "Executing package-specific Kyverno policy tests using the default values for the ${CI_PROJECT_NAME} chart..."
         helm template "${CI_PROJECT_NAME}" chart/ \
            --namespace="${CI_PROJECT_NAME}" \
            | kyverno apply "${policy_directory}" --resource -
      fi
      echo -e "⬆️  \e[34mSee the policy test results above\e[37m ⬆️"
   else
      if ${DEBUG}; then
         echo "A '${policy_directory}' directory with YAML policy manifests was not found in the ${CI_PROJECT_NAME} package repository...skipping..."
      fi
   fi
}

# Executable function
function main() {
   echo -e "\e[0Ksection_start:$(date +%s):kyverno_policy_tests[collapsed=true]\r\e[0K\e[33;1mKyverno Policy Tests\e[37m"
   get_kyverno_policy_manifests
   add_warn_annotation
   global_policy_tests
   package_policy_tests
   rm -rf "${KYVERNO_POLICIES_DIRECTORY}"
   rm -rf "${POLICY_MANIFESTS_DIRECTORY}"
   echo -e "\e[0Ksection_end:$(date +%s):kyverno_policy_tests\r\e[0K"
}

main