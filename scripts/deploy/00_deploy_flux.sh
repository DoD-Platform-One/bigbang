#!/usr/bin/env bash

set -ex

# install flux with the dedicated helper script
./scripts/install_flux.sh \
  --registry-username 'robot$bb-dev-imagepullonly' \
  --registry-password "${REGISTRY1_PASSWORD}" \
  --registry-email bigbang@bigbang.dev 