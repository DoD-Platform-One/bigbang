#!/usr/bin/env bash

# obtain the default version
default_version=$(git show origin/${CI_DEFAULT_BRANCH}:${CHART_FILE} | grep -oP 'version: \K(.*)')

# check for command error
if [ $? -ne 0 ]; then
  echo "Error: An unknown error has occurred while attempting to retrieve the default version from ${CHART_FILE}"
  exit 1
fi

# obtain the local version
local_version=$(cat ${CHART_FILE} | grep -oP 'version: \K(.*)')

# check for command error
if [ $? -ne 0 ]; then
  echo "Error: An unknown error has occurred while attempting to retrieve the local version from ${CHART_FILE}"
  exit 1
fi

# debug print
echo "Default version: $default_version"
echo "Local version: $local_version"

# error if the versions are not different
if [[ "$default_version" == "$local_version" ]]; then
  echo "The version has not been updated in ${CHART_FILE}, please update this file"
  exit 1
fi

# default to success
exit 0