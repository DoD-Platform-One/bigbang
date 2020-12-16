#!/bin/bash
set -ex

mkdir -p repos/

# Clone core
yq r "chart/values.yaml" "*.git.repo" | while IFS= read -r repo; do
    git -C repos/ clone --no-checkout $repo
done

# Clone packages
yq r "chart/values.yaml" "addons.*.git.repo" | while IFS= read -r repo; do
    git -C repos/ clone --no-checkout $repo
done
