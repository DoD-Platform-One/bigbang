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

- verify you have all the dependencies installed (see INSTALL-DEPENDENCIES.md)
- run the script for the pipeline you want to run, passing in the necessary parameters
- ex: `./local-package-pipeline.sh /my/path/to/logging` would run the package pipeline against the logging app
