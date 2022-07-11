#!/usr/bin/env bash

set -e
trap 'echo exit at ${0}:${LINENO}, command was: ${BASH_COMMAND} 1>&2' ERR

IMAGES_TXT="images.txt"
REGISTRY_IMAGE="registry:2"
REGISTRY_PACKAGE_IMAGE="registry:package"
REGISTRY_PACKAGE_TGZ="${REGISTRY_PACKAGE_IMAGE}.tar.gz"

# $1 = image_original - original full image url from existing repository
function get_image_sections {
  image_full=$(echo ${1} | sed -n 's/^.*\/\(.*:.*\)$/\1/p')
  image_base=$(echo ${image_full} | sed -n 's/\(^.*\):\(.*$\)/\1/p')
  image_tag=$(echo ${image_full} | sed -n 's/\(^.*\):\(.*$\)/\2/p')
  # [ -z "${image_full}" ] && { echo "Error: Unable to set image full variable"; exit 1; }
  # [ -z "${image_base}" ] && { echo "Error: Unable to set image base variable"; exit 1; }
  # [ -z "${image_tag}" ] && { echo "Error: Unable to set image tag variable"; exit 1; }
}

# $1 = image_base - image name and tag (nginx:latest)
# $1 = image_tag - image tag only (latest)
function verify_catalog_image {
  echo "Verifying \"${1}\" exists in registry catalog with tag \"${2}\""
  reg_tag=$(curl -sX GET http://localhost:5000/v2/${1}/tags/list | jq -r '.tags | .[0]')
  if [ "${2}" != "${reg_tag}" ]; then
    echo "Error: Unable to verify ${1} exists in catalog"
    exit 1
  fi
}

function purge_registry_containers {
  echo "Stopping local registry containers"
  docker stop registry &>/dev/null || true
  docker rm registry &>/dev/null || true
}

function purge_registry_images {
  echo "Removing local registry images"
  docker image rm ${REGISTRY_IMAGE} &>/dev/null || true
  docker image rm ${REGISTRY_PACKAGE_IMAGE} &>/dev/null || true
}

echo "Removing local registry package tgz"
rm -rf ${REGISTRY_PACKAGE_TGZ}

purge_registry_containers
purge_registry_images

echo "Creating initial registry container"
docker run -d -p 5000:5000 --name registry ${REGISTRY_IMAGE} &>/dev/null

echo "--"
for image_original in $(sed '/^$/d' ${IMAGES_TXT}); do
  get_image_sections ${image_original}
  echo "Referencing \"${image_original}\""
  echo "Uploading to registry as \"${image_base}\" with tag \"${image_tag}\""
  docker pull ${image_original} >/dev/null
  docker tag ${image_original} localhost:5000/${image_full} >/dev/null
  docker push localhost:5000/${image_full} >/dev/null
  verify_catalog_image ${image_base} ${image_tag}
  echo "--"
done

# TODO - is a pass-through proxy needed? - https://docs.docker.com/registry/recipes/mirror/
echo "Creating persistent package inside registry container"
docker cp registry-config.yml registry:/etc/docker/registry/config.yml >/dev/null
docker exec -it registry cp -r /var/lib/registry/ /var/lib/registry-package >/dev/null

echo "Commiting initial registry image to package registry image"
docker commit registry ${REGISTRY_PACKAGE_IMAGE} >/dev/null

purge_registry_containers

echo "Creating package registry container"
docker run -d -p 5000:5000 --name registry ${REGISTRY_PACKAGE_IMAGE} &>/dev/null

echo "--"
for image_original in $(sed '/^$/d' ${IMAGES_TXT}); do
  get_image_sections ${image_original}
  verify_catalog_image ${image_base} ${image_tag}
done
echo "--"

purge_registry_containers

echo "Saving local registry package tgz"
docker save ${REGISTRY_PACKAGE_IMAGE} | gzip --stdout > ${REGISTRY_PACKAGE_TGZ}

purge_registry_images