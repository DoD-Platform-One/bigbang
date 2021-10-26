#!/usr/bin/env bash

# exit on error
set -e
trap 'echo ❌ exit at ${0}:${LINENO}, command was: ${BASH_COMMAND} 1>&2' ERR

# Quick check for non iron bank images
echo "Showing images not from ironbank:"
# Ignore rancher images since those are from k3d
kubectl get pods -A -o jsonpath="{..image}" | tr -s '[[:space:]]' '\n' | sort | uniq -c | grep -v "registry1" | ( grep -v "rancher" || echo "None" )
