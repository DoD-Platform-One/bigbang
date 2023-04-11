#!/bin/bash

# Must have a running cluster with Flux CRDs installed 
kubectl proxy --port 8080 &
proxy_pid=$!
sleep 5

VALUES_FILE="../chart/values.schema.json"

# Fetch schema from Kube API for flux + postRenderers
POST_RENDERERS=$(curl http://localhost:8080/openapi/v3/apis/helm.toolkit.fluxcd.io/v2beta1 | jq '.components.schemas["io.fluxcd.toolkit.helm.v2beta1.HelmRelease"].properties.spec.properties' | jq '.postRenderers')
FLUX=$(curl http://localhost:8080/openapi/v3/apis/helm.toolkit.fluxcd.io/v2beta1 | jq '.components.schemas["io.fluxcd.toolkit.helm.v2beta1.HelmRelease"].properties.spec.properties' | jq 'del('.postRenderers',  '.dependsOn',  '.valuesFrom', '.targetNamespace', '.chart')')

# Substitute existing values
jq --argjson subs "$POST_RENDERERS" '.["$defs"].postRenderers = $subs' $VALUES_FILE | sponge $VALUES_FILE
jq --argjson subs "$FLUX" '.["$defs"].flux = $subs' $VALUES_FILE | sponge $VALUES_FILE

kill $proxy_pid