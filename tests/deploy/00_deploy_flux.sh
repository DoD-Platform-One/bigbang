#!/usr/bin/env bash

set -e
trap 'echo ❌ exit at ${0}:${LINENO}, command was: ${BASH_COMMAND} 1>&2' ERR
set -x

# install flux with the dedicated helper script
./scripts/install_flux.sh \
  --registry-username "${REGISTRY1_USER}" \
  --registry-password "${REGISTRY1_PASSWORD}" \
  --registry-email bigbang@bigbang.dev 
