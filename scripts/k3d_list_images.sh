#!/usr/bin/env bash

NODE_NAME=$(kubectl get no -o name | grep -o 'k3d-.*-server-0')
RUNTIME_ENDPOINT=unix:///run/k3s/containerd/containerd.sock
IMAGE_ENDPOINT=unix:///run/k3s/containerd/containerd.sock

docker exec -i $NODE_NAME crictl -r $RUNTIME_ENDPOINT -i $IMAGE_ENDPOINT images -o json | jq -r '.images[].repoTags[0] | select(. != null)'