# Run Big Bang Package Pipelines Locally

## Options for Running Pipelines

There are two options provided to run the pipelines locally:
- Local-Docker-Pipeline
- Local-Pipeline

The preferred method is the Local-Docker-Pipeline since it is easier to get started with, but both will work.

Local-Docker-Pipeline:
- Pipeline is run entirely in a Docker container, no need to install additional tools besides Docker
- Execution can be slower due to Docker-in-Docker and other complexities
- Scripts ocated under `local-docker-pipeline` directory

Local-Pipeline:
- Pipeline is run entirely on local dev machine, requires additional tools (see the `INSTALL-DEPENDENCIES.md` file under the `local-pipeline` directory)
- Execution could be faster due to less complexity with Docker
- Scripts located under `local-pipeline` directory

## How to run (Local-Docker-Pipeline)

- Download the folder `local-docker-pipeline`
- Run `run-pipeline.sh` passing in the fully qualified app path (i.e. `./run-pipeline.sh /my/path/to/argocd/app`)
- View the results (stages passed, errors, etc)
- If the pipeline made it to Cypress testing you will see a `cypress-results` folder with the Cypress screenshot/video artifacts in your local directory
- NOTE: For efficiency, do not delete the exited docker container. The script will handle it being deleted, but pulling docker images will make execution time longer.

## How to run (Local-Pipeline)

- Download the folder `local-pipeline`
- Run `run-pipeline.sh` passing in the fully qualified app path (i.e. `./run-pipeline.sh /my/path/to/argocd/app`)
- View the results (stages passed, errors, etc)
- If the pipeline made it to Cypress testing you will see a `cypress-results` folder with the Cypress screenshot/video artifacts in the app directory

## Notes

- Cypress is not running currently on the `local-pipeline`
- Endpoints are not being exposed currently on either pipeline from the k3d cluster, Cypress should be expected to fail