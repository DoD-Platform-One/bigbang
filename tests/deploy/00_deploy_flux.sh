#!/usr/bin/env bash

set -ex
trap 'echo exit at ${0}:${LINENO}, command was: ${BASH_COMMAND} 1>&2' ERR

# install flux with the dedicated helper script
./scripts/install_flux.sh \
  --registry-username 'robot$bb-dev-imagepullonly' \
  --registry-password "${REGISTRY1_PASSWORD}" \
  --registry-email bigbang@bigbang.dev 