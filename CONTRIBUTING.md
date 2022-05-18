# Contributing to Big Bang

Thanks for taking the time to contribute to BigBang!

Table of Contents:

- [Contributing to Big Bang](#contributing-to-big-bang)
  - [Developers Guide](#developers-guide)
  - [Local Git Setup](#local-git-setup)
    - [Pre-commit hooks](#pre-commit-hooks)
      - [Local Setup](#local-setup)
        - [Prereqs](#prereqs)
        - [Steps](#steps)
      - [Combining Multiple Commits](#combining-multiple-commits)
  - [Iron Bank Images](#iron-bank-images)
  - [Local Kubernetes cluster](#local-kubernetes-cluster)
  - [Deploying Big Bang (Quick Start)](#deploying-big-bang-quick-start)
  - [Testing Big Bang Development Changes](#testing-big-bang-development-changes)
  - [DNS](#dns)
  - [Secrets & Certificates](#secrets--certificates)
  - [Merge requests process](#merge-requests-process)

## Developers Guide 

Big Bang is designed in such a way as to be as easily deployed locally as it is in production.  In fact, most contributions begin locally.

## Iron Bank Images

Per the [charter](https://repo1.dso.mil/platform-one/big-bang/charter), all Big Bang packages will leverage container images from [IronBank](https://ironbank.dso.mil/).  In order to pull these images, ImagePullSecrets must be provided to BigBang.  To obtain access to these images, follow the guides below.  These steps should NOT be used for production since the API keys for a user are only valid when the user is logged into [Registry1](https://registry1.dso.mil)

1) Register for a free Ironbank account [Here](https://sso-info.il2.dso.mil/new_account.html)
1) Log into the [Iron Bank Registry](https://registry1.dso.mil), in the top right click your *Username* and then *User Profile* to get access to your *CLI secret*/API keys.
1) When installing BigBang, set the Helm Values `registryCredentials.username` and `registryCredentials.password` to match your Registry1 username and API token

## Local Kubernetes cluster

Follow the steps below to get a local Kubernetes cluster for Big Bang  using [k3d](https://k3d.io/).

```bash
# Create a local k3d cluster with the appropriate port forwards (tested on version 5.4.1)
k3d cluster create --k3s-arg "--no-deploy=metrics-server,traefik@server:*" -p 80:80@loadbalancer -p 443:443@loadbalancer
```

## Deploying Big Bang (Quick Start)

For development, it is quicker to test changes without having to push to Git.  To do this, we can bypass Flux2 and deploy Big Bang directly with its Helm chart.

Start by creating `myvalues.yaml` to configure your local Big Bang.  Big Bang's template repository contains a starter [development values.yaml](https://repo1.dso.mil/platform-one/big-bang/customers/template/-/blob/main/dev/configmap.yaml).

Configure `myvalues.yaml` to suit your needs.

```bash
# Deploy the latest fluxv2 with Iron Bank images
# For development, you can use flux from the internet using 'flux install`
# Be aware, the internet version is likely newer than the Iron Bank version
./scripts/install_flux.sh

# Apply a local version of the Big Bang chart
# NOTE: This is the alternative to deploying a HelmRelease and having flux manage it, we use a local copy to avoid having to commit every change
helm upgrade -i bigbang chart -n bigbang --create-namespace -f myvalues.yaml

# It may take Big Bang up to 10 minutes to recognize your changes and start to deploy them.  This is based on the flux `interval` value set for polling.  You can force Big Bang to immediately check for changes by running the ./scripts/sync.sh script.
./scripts/sync.sh
```

For more extensive development, use the [Development Guide](./docs/developer).

## Testing Big Bang Development Changes

Development changes should be tested using a full GitOps environment.  The [Big Bang environment template](https://repo1.dso.mil/platform-one/big-bang/customers/template/) should be replicated, either on a branch or new repository, to start your deployment.  Follow the instructions in the [template's readme](https://repo1.dso.mil/platform-one/big-bang/customers/template/-/tree/main/README.md) and in the [Big Bang docs](./docs) for configuration.

Follow the [Big Bang documentation](./docs) for testing a full deployment of Big Bang.

## DNS

To ease with local development, the TLD `bigbang.dev` is maintained by the Big Bang team with the CNAME record:

`CNAME: *.bigbang.dev -> 127.0.0.1`

All routable endpoints BigBang deploys will use the TLD of `bigbang.dev` by default.  It is expected that consumers modify this appropriately for their environment.

## Secrets & Certificates

Follow instructions in the [Big Bang encryption guide](./docs/encryption.md) for how to encrypt and decrypt secrets.

## Merge requests process

The merge request process is provided as an overview of the pipeline stages required to get a commit merged.

Follow instruction in [CI-Workflow](./docs/developer/ci-workflow.md) for specific details on the pipeline stages.

