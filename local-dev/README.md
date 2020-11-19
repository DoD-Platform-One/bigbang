# Big Bang Pipelines Locally

## Dependencies

- tree
- helm
- helm conftest plugin
- docker
- k3d
- kubectl
- cypress


## How to run

- verify you have all the dependencies installed
- run the script for the pipeline you want to run, passing in the necessary parameters
- ex: `./local-package-pipeline.sh /home/me/core-apps/logging` would run the package pipeline against the logging app
