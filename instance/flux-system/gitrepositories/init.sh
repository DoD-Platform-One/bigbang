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

deploy_flux() {
  info "Installing flux components"
  # Apply flux components
  kustomize build base/flux/toolkit | kubectl apply -f -

  info "Waiting for flux components to initialize"
  kubectl wait --for=condition=available --timeout=60s --all deployments -n flux-system
}

deploy_this_repo() {
  export branch=$(git rev-parse --abbrev-ref HEAD)
  export repo=$(git config --get remote.origin.url)
  export env="dev"

  info "Deploying the current repo: ${branch} targetting the branch: ${repo}"

  kustomize build "${curdir}" | envsubst | kubectl apply -f -
}

bootstrap() {
  curdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

  deploy_this_repo

  case "$1" in
  "dev")
    kustomize build base/flux/chart-repositories | kubectl apply -f -
    info "Stopping at empty flux"
    ;;
  *)
    info "Bootstrapping from the current repo"
    kustomize build "${curdir}/.." | kubectl apply -f -
  esac
}

{
  need "kustomize"
  need "kubectl"
  need "envsubst"
  need "git"

  deploy_flux
  
  bootstrap "$1"
}