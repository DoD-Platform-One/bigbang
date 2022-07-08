#! /usr/bin/env bash

echo "👉 This script may take 5-10 minutes to complete, so grab a coffee or something."
echo "👉 If it hangs, CTRL+C and run it again"

echo "👉 Updating all submodules"
git submodule update --init --recursive

echo "👉 Fetching latest remote commits"
git submodule update --remote

# echo "👉 Fetching tags from all submodules"
# IFS=$'\n'
# for DIR in $(git submodule foreach -q sh -c pwd); do
#     cd "$DIR" && git fetch --all --tags --force --quiet &
# done
# wait
