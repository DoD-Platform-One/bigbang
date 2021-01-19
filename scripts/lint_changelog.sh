#!/usr/bin/env bash

# diff the file silently, while still printing errors
git diff --exit-code origin/${CI_DEFAULT_BRANCH}:${CHANGELOG_FILE} ${CHANGELOG_FILE} >/dev/null

# exit code of 0 indicates non changed file
if [ $? -eq 0 ]; then
  echo "No changes were detected in ${CHANGELOG_FILE}, please update this file"
  exit 1
fi

# exit code other than 0 and 1 is an error
# IE - different file names between branches
# check for this and fail accordingly
if [ $? -ne 1 ]; then
  echo "Error: An unknown error has occurred while linting ${CHANGELOG_FILE}"
  exit 1
fi

# default to success
exit 0