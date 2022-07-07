#! /usr/bin/env bash

set -eu

echo "👉 Fetching tags from all submodules"

IFS=$'\n'
for DIR in $(git submodule foreach -q sh -c pwd); do
    cd "$DIR" && git fetch --all --tags --force &
done
wait
