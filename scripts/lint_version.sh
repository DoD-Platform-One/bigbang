#!/usr/bin/env bash

# obtain the default chart version
chart_default_version=$(git show origin/${CI_DEFAULT_BRANCH}:${CHART_FILE} | grep -oP 'version: \K(.*)')

# check for command error
if [ $? -ne 0 ]; then
  echo "Error: An unknown error has occurred while attempting to retrieve the default version from ${CHART_FILE}"
  exit 1
fi

# obtain the local chart version
chart_local_version=$(cat ${CHART_FILE} | grep -oP 'version: \K(.*)')

# check for command error
if [ $? -ne 0 ]; then
  echo "Error: An unknown error has occurred while attempting to retrieve the local version from ${CHART_FILE}"
  exit 1
fi

# obtain the default base git repository tag
basegit_default_tag=$(git show origin/${CI_DEFAULT_BRANCH}:${BASEGIT_FILE} | grep -oP 'tag: \K(.*)')

# check for command error
if [ $? -ne 0 ]; then
  echo "Error: An unknown error has occurred while attempting to retrieve the default tag from ${BASEGIT_FILE}"
  exit 1
fi

# obtain the local base git repository tag
basegit_local_tag=$(cat ${BASEGIT_FILE} | grep -oP 'tag: \K(.*)')

# check for command error
if [ $? -ne 0 ]; then
  echo "Error: An unknown error has occurred while attempting to retrieve the local tag from ${BASEGIT_FILE}"
  exit 1
fi

# debug print
echo "Default branch chart version (${CHART_FILE}): $chart_default_version"
echo "Local branch chart version (${CHART_FILE}): $chart_local_version"

# assume success
exit_code=0

# error if the versions are not different
if [[ "$chart_default_version" == "$chart_local_version" ]]; then
  echo "The version has not been updated in ${CHART_FILE}, please update this file"
  exit_code=1
fi

echo "--------------------------------------------------------"

echo "Default branch base git repository tag (${BASEGIT_FILE}): $basegit_default_tag"
echo "Local branch base git repository tag (${BASEGIT_FILE}): $basegit_local_tag"

# error if the versions are not different
if [[ "$chart_default_version" == "$chart_local_version" ]]; then
  echo "The tag has not been updated in ${BASEGIT_FILE}, please update this file"
  exit_code=1
fi

# exit with stored code
exit $exit_code