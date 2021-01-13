#!/usr/bin/env bash

# store failure
failure=false

# debug output
echo "Linting all commits between $CI_DEFAULT_BRANCH and $CI_COMMIT_REF_NAME"
echo "--------------------------------------------------------"

# loop over commit sha's for commits that exist in this branch but not the default branch
for sha in $(git log origin/$CI_DEFAULT_BRANCH..origin/$CI_COMMIT_REF_NAME --format=format:%H); do
  # get the commit message from the sha
  message=$(git log --format=format:%s -n 1 $sha)
  # debug output sha and message
  echo "Linting commit: $sha - $message"
  # lint message and store possible failure
  if ! echo "$message" | npx commitlint; then failure=true; fi
done

# if we have a failure
if $failure; then
  # guide developer to resolution
  echo "--------------------------------------------------------"
  echo "You have commits that have failed linting because their content does not follow conventional standards"
  echo "You must rebase, squash, or amend; and implement conventional standards on all commits for this branch"
  echo "Commit standards guide - https://www.conventionalcommits.org/"
  echo "--------------------------------------------------------"
  echo "Quick tip - Squash commits for $CI_COMMIT_REF_NAME"
  echo "> git checkout $CI_COMMIT_REF_NAME"
  echo "> git reset \$(git merge-base $CI_DEFAULT_BRANCH \$(git rev-parse --abbrev-ref HEAD))"
  echo "> git add -A"
  echo "> git commit -m \"feat: example conventional commit\""
  echo "> git push --force"
  exit 1
fi