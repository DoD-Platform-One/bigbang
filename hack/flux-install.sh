#!/bin/bash

# This script will deploy your Iron Bank pull secret to a secret in Kubernetes
# Using the pull secret, it will download and install Flux2 on the cluster
# After Flux2 is installed, the secret will be removed from the cluster

# Constants
reg=registry1.dso.mil
repo=ironbank/fluxcd
fluxver="v0.2.4"
ns=flux-system
sec=regcred

# Options
while getopts n: flag
do
  case "${flag}" in
    n) ns=${OPTARG};;
  esac
done

# Check tools
check_tool() {
  {
    which $1 > /dev/null
  } || {
    echo "Need to install $1"
    exit 1
  }
}
check_tool docker
check_tool kubectl
check_tool flux

flux check --pre
if [ $? -ne 0 ]; then echo ERROR: Flux prerequisites failed!; exit 1; fi

echo
echo Logging into ${reg} ...

# Authenticate with registry
docker login ${reg}
if [ $? -ne 0 ]; then echo ERROR: Registry authentication failed!; exit 1; fi

echo
echo Setting up image pull credentials in cluster ...

# Generate secret
if ! kubectl get namespace ${ns} > /dev/null 2>&1; then
  kubectl create ns ${ns};
  if [ $? -ne 0 ]; then echo ERROR: Namespace creation failed!; exit 1; fi
fi
if kubectl get secret ${sec} -n ${ns} > /dev/null 2>&1; then
  kubectl delete secret ${sec} -n ${ns}
fi
kubectl create secret generic ${sec} -n ${ns} --from-file=.dockerconfigjson=${HOME}/.docker/config.json --type=kubernetes.io/dockerconfigjson
if [ $? -ne 0 ]; then echo ERROR: Secret creation failed!; exit 1; fi

echo Successfully setup image pull credentials.
echo
echo Installing flux ${fluxver} from ${reg} ...
echo Please be patient.  It can take a long time to pull the images from ${reg}.

# Install flux
flux install -n ${ns} --registry=${reg}/${repo} --image-pull-secret=${sec} --version=${fluxver} --timeout 30m
if [ $? -ne 0 ]; then echo ERROR: Flux install failed!!; exit 1; fi

echo
echo Cleaning up image pull credentials

# Remove secret (no longer needed)
kubectl delete secret ${sec} -n ${ns}
if [ $? -ne 0 ]; then echo ERROR: Secret deletion failed!; exit 1; fi

echo
echo Successfull installed flux ${fluxver} from ${reg}