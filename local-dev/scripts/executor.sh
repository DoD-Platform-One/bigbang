#!/bin/bash
waitForDocker() {( set -e
    printf "Waiting for Docker to startup..."
    sleep_time=0
    while [ true ]
    do
        docker version > /dev/null 2>&1 && printf "\n" && break
        printf "."
        sleep 0.5
        sleep_time+=0.5
        if [ sleep_time == 30 ]
        then
            echo "Docker in docker failed to startup..."
            exit 1
        fi
    done
    return 0
)}

# Runs the conftest stage of the package pipeline
conftest() {( set -e
    git clone https://repo1.dsop.io/platform-one/big-bang/pipeline-templates/pipeline-templates.git pipeline-templates-dev
    echo "Directory structure of repository:"
    tree $1
    echo "Generic configuration validation tests:"
    helm conftest $1/chart --policy pipeline-templates-dev/policies
    if [ -d "$1/policy" ]; then
        echo "App specific configuration validation tests:"
        helm conftest chart --policy $1/policy
    fi
)}

# Runs the package test stage of the package pipeline
packagetest() {( set -e
    waitForDocker
    k3d cluster create package-pipeline-local --k3s-server-arg "--disable=metrics-server" --k3s-server-arg "--disable=traefik" -p 80:80@loadbalancer -p 443:443@loadbalancer --wait --agents 1 --servers 1
    while ! (kubectl get node | grep "agent" > /dev/null); do sleep 3; done
    kubectl wait --for=condition=available --timeout 600s -A deployment --all > /dev/null
    kubectl wait --for=condition=ready --timeout 600s -A pods --all --field-selector status.phase=Running > /dev/null
    echo "Istio install"
    istioctl install -y > /dev/null
    echo "Package install"
    helm install pipeline-local $1/chart -n pipeline-local --create-namespace -f $1/tests/test-values.yml
    kubectl wait --for=condition=available --timeout 600s -A deployment --all > /dev/null
    kubectl wait --for=condition=ready --timeout 600s -A pods --all --field-selector status.phase=Running > /dev/null
    echo "Package tests"
    kubectl get ingress --all-namespaces
    kubectl get all -A
    cd $1/tests
    cy-run.sh
)}

if [ -z $1 ]
then
    echo "Please specify the app path as first argument."
    exit 1
elif [[ $1 == *"../"* ]]
then
    echo "Please use the absolute path for the app."
    exit 1
elif [ ! -d $1 ]; then
    echo "Please specify the app path as first argument. If you have, verify the path exists."
    exit 1
fi

conftest $1
exit_status=$?
if [ ${exit_status} -eq 0 ]; then
    rm -rf pipeline-templates-dev
    echo "Conftest succeeded."
    packagetest $1
    exit_status=$?
    if [ ${exit_status} -eq 0 ]; then
        k3d cluster delete package-pipeline-local
        echo "Package tests succeeded."
        echo "Pipeline passed (2/2 stages passed)."
    else
        k3d cluster delete package-pipeline-local
        echo "Package tests failed."
        echo "Pipeline failed (1/2 stages passed)."
    fi
else
    rm -rf pipeline-templates-dev
    echo "Conftest failed."
    echo "Pipeline failed (0/2 stages passed)."
fi