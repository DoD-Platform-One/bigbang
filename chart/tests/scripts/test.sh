#!/bin/bash
set -ex

export HOME=/test

/bin/crane auth login ${docker_host} -u ${docker_user} -p ${docker_password} ${docker_args}

echo "pulling image..."
/bin/crane pull alpine:latest alpine-push.tar

image_tag=$RANDOM

echo "pushing image to nexus registry..."

# Retry due to timing with Nexus docker registry being ready for our request and finicky package CI
for i in {1..5}; do 
  /bin/crane push alpine-push.tar ${docker_host}/alpine:${image_tag} ${docker_args} && export EC=$? || export EC=$?
  if [[ $EC == 0 ]]; then
    break
  fi
  sleep 10
done

if [[ $EC != 0 ]]; then
  echo "error while pushing to nexus registry, review logs above"
  exit 1
fi

# Retry due to timing with Nexus docker registry being ready for our request and finicky package CI
echo "pulling image from nexus registry..."
for i in {1..5}; do 
  /bin/crane pull ${docker_host}/alpine:${image_tag} alpine-pull.tar ${docker_args} && export EC=$? || export EC=$?
  if [[ $EC == 0 ]]; then
    break
  fi
  sleep 10
done

if [[ $EC != 0 ]]; then
  echo "error while pulling from nexus registry, review logs above"
  exit 1
fi

echo "All tests complete!"
