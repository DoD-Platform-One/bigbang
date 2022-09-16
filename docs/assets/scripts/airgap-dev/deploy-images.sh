#!/usr/bin/env bash

set -e
trap 'echo exit at ${0}:${LINENO}, command was: ${BASH_COMMAND} 1>&2' ERR

REGISTRY_PACKAGE_IMAGE="registry:package"
REGISTRY_PACKAGE_TGZ="${REGISTRY_PACKAGE_IMAGE}.tar.gz"

function purge_registry_containers {
  echo "Stopping local registry containers"
  docker stop registry &>/dev/null || true
  docker rm registry &>/dev/null || true
}

function purge_registry_images {
  echo "Removing local registry images"
  docker image rm ${REGISTRY_PACKAGE_IMAGE} &>/dev/null || true
}

purge_registry_containers
purge_registry_images

echo "Loading local registry package tgz"
docker load < ${REGISTRY_PACKAGE_TGZ}

echo "Creating package registry container"
docker run -d -p 5000:5000 --name registry ${REGISTRY_PACKAGE_IMAGE} >/dev/null

echo "Showing package container registry catalog"
sleep 1; curl -sX GET http://localhost:5000/v2/_catalog