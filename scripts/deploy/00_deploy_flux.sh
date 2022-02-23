#!/usr/bin/env bash

set -e
source ${PIPELINE_REPO_DESTINATION}/library/templates.sh

# install flux with the dedicated helper script
./scripts/install_flux.sh \
  --registry-username "${REGISTRY1_USER}" \
  --registry-password "${REGISTRY1_PASSWORD}" \
  --registry-email bigbang@bigbang.dev 