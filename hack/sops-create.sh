#!/bin/bash

# This script will deploy install the bigbang-dev.asc private key into a sops-gpg secret in the bigbang namespace

# Constants
file=$(realpath `dirname "$0"`)/bigbang-dev.asc
ns=bigbang
secret=sops-gpg
key=bigbangkey

# Check tools
check_tool() {
  {
    which $1 > /dev/null
  } || {
    echo "Need to install $1"
    exit 1
  }
}
check_tool kubectl

echo Installing SOPS secret from ${file} into ${ns}/${secret}...

kubectl create namespace ${ns} 2> /dev/null
kubectl create secret generic ${secret} --namespace=${ns} --from-file=${key}=${file}
if [ $? -ne 0 ]; then echo ERROR: Secret creation failed!; exit 1; fi

echo Success!
echo