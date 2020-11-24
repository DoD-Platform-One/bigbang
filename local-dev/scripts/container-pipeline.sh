#!/bin/bash
start_time="$(date -u +%s)"
executionpath=`dirname $0`

# Verify app path was passed
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

# Check for existing local builder instance and start it, otherwise run a new instance
if [ "$(docker ps -aq -f status=exited -f name=k3d-builder-local)" ]
then
    docker start k3d-builder-local
else
    docker run -d --privileged --name k3d-builder-local registry.dsop.io/platform-one/big-bang/pipeline-templates/pipeline-templates/k3d-builder-local:0.0.1
fi

# Copy the specified app into the container and run the pipeline
cp $executionpath/executor.sh $1
docker cp $1 k3d-builder-local:/app
docker exec -it -w /app k3d-builder-local ./executor.sh /app

# Check if cypress had any artifacts and copy those out to ./cypress-results
docker exec k3d-builder-local [ -d "/app/tests/cypress/screenshots" ] && mkdir -p ./cypress-results && docker cp k3d-builder-local:/app/tests/cypress/screenshots/ ./cypress-results/screenshots
docker exec k3d-builder-local [ -d "/app/tests/cypress/videos" ] && mkdir -p ./cypress-results && docker cp k3d-builder-local:/app/tests/cypress/videos/ ./cypress-results/videos

# Clean up the app from the container, stop container, remove the script from app directory
docker exec -it k3d-builder-local rm -rf /app
docker stop k3d-builder-local
rm $1/executor.sh

end_time="$(date -u +%s)"
elapsed_seconds="$(($end_time-$start_time))"
echo "Pipeline run finished in $elapsed_seconds seconds."