#!/bin/bash

set -e

# info logs the given argument at info log level.
info() {
    echo "[INFO] " "$@"
}

# warn logs the given argument at warn log level.
warn() {
    echo "[WARN] " "$@" >&2
}

# fatal logs the given argument at fatal log level.
fatal() {
    echo "[ERROR] " "$@" >&2
    exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || fatal "'$1' required on \$PATH but not found"
}

{
  need "flux"
  need "helm"
  need "kubectl"

  info "Installing flux into current cluster..."
  flux install

  info "💣💣💣..."
  helm template bigbang chart/ -n flux-system | kubectl apply -f -
  info "💥💥💥"
}