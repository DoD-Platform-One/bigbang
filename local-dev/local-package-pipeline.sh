#!/bin/bash
# Runs the conftest stage of the package pipeline
conftest() {( set -e
    echo "Directory structure of repository:"
    tree $1
    echo "Generic configuration validation tests:"
    helm conftest $1/chart --policy ../policies
    if [ -d "$1/policy" ]; then
        echo "App specific configuration validation tests:"
        helm conftest chart --policy $1/policy
    fi
)}

# Runs the package test stage of the package pipeline
packagetest() {( set -e
    k3d cluster create package-pipeline-devtest --k3s-server-arg "--disable=metrics-server" --k3s-server-arg "--disable=traefik" -p 80:80@loadbalancer -p 443:443@loadbalancer --wait --agents 1 --servers 1
    while ! (kubectl get node | grep "agent" > /dev/null); do sleep 3; done
    kubectl wait --for=condition=available --timeout 600s -A deployment --all > /dev/null
    kubectl wait --for=condition=ready --timeout 600s -A pods --all --field-selector status.phase=Running > /dev/null

    # Place kubernetes package test here
    echo "Package install"
    helm install devtest $1/chart -n devtest --create-namespace -f $1/tests/test-values.yml
    kubectl wait --for=condition=available --timeout 600s -A deployment --all > /dev/null
    kubectl wait --for=condition=ready --timeout 600s -A pods --all --field-selector status.phase=Running > /dev/null
    echo "Package tests"
    kubectl get ingress --all-namespaces
    kubectl get all -A
    cypress verify
)}

if [ -z $1 ]
then
    echo "Please specify the app path as first argument."
    exit 1
elif [[ $1 == *"../"* ]]
then
    echo "Please use the absolute path for the app."
    exit 1
fi

conftest $1
exit_status=$?
if [ ${exit_status} -eq 0 ]; then
    echo "Conftest succeeded."
    packagetest $1
    exit_status=$?
    if [ ${exit_status} -eq 0 ]; then
        k3d cluster delete package-pipeline-devtest
        echo "Package tests succeeded."
        echo "Pipeline passed (2/2 stages passed)."
    else
        k3d cluster delete package-pipeline-devtest
        echo "Package tests failed."
        echo "Pipeline failed (1/2 stages passed)."
    fi
else
    echo "Conftest failed."
    echo "Pipeline failed (0/2 stages passed)."
fi