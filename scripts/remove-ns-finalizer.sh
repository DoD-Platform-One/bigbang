#!/bin/sh

NS=$1
shift

kubectl get ns $NS -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/$NS/finalize" -f -
