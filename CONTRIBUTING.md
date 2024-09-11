# Contributing to Big Bang

Thanks for taking the time to contribute to Big Bang!

If you are coming from `repo1.dso.mil` and have an account at `login.dso.mil`, please keep reading. If you are coming from or looking for the [project on Github](https://github.com/DoD-Platform-One) and wanting to make a Pull Request without a `dso.mil` account, please see the last section [External Github Contributions](#community-contributions-to-dod-platform-one-via-github).

Table of Contents:

- [Contributing to Big Bang](#contributing-to-big-bang)
  - [Developers Guide](#developers-guide)
  - [Iron Bank Images](#iron-bank-images)
  - [Local Kubernetes cluster](#local-kubernetes-cluster)
  - [Deploying Big Bang (Quick Start)](#deploying-big-bang-quick-start)
  - [Testing Big Bang Development Changes](#testing-big-bang-development-changes)
  - [DNS](#dns)
  - [Secrets & Certificates](#secrets--certificates)
  - [Merge requests process](#merge-requests-process)
  - [Security Consideration](#security-considerations)
  - [External Github Contributions](#community-contributions-to-dod-platform-one-via-github)

## Developers Guide

Big Bang is designed in such a way as to be as easily deployed locally as it is in production. In fact, most contributions begin locally.

## Iron Bank Images

Per the [charter](https://repo1.dso.mil/big-bang/charter), all Big Bang packages will leverage container images from [IronBank](https://ironbank.dso.mil/).  In order to pull these images, ImagePullSecrets must be provided to Big Bang. To obtain access to these images, follow the guides provided in this document. These steps should NOT be used for production since the API keys for a user are only valid when the user is logged into [Registry1](https://registry1.dso.mil)

1) Register for a free Iron Bank account [Here](https://sso-info.il2.dso.mil/new_account.html).
1) Log into the [Iron Bank Registry](https://registry1.dso.mil), in the top right click your *Username* and then *User Profile* to get access to your *CLI secret*/API keys.
1) When installing BigBang, set the Helm Values `registryCredentials.username` and `registryCredentials.password` to match your Registry1 username and API token.

## Local Kubernetes cluster

Follow the steps below to get a local Kubernetes cluster for Big Bang  using [k3d](https://k3d.io/).

```bash
# Create a local k3d cluster with the appropriate port forwards (tested on version 5.4.1).
k3d cluster create --k3s-arg "--no-deploy=metrics-server,traefik@server:*" -p 80:80@loadbalancer -p 443:443@loadbalancer
```

## Deploying Big Bang (Quick Start)

For development, it is quicker to test changes without having to push to Git. To do this, we can bypass Flux2 and deploy Big Bang directly with its Helm chart.

Start by creating `myvalues.yaml` to configure your local Big Bang. The Big Bang template repository contains a starter [development values.yaml](https://repo1.dso.mil/big-bang/customers/template/-/blob/main/package-strategy/configmap.yaml).

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

Development changes should be tested using a full GitOps environment. The [Big Bang environment template](https://repo1.dso.mil/big-bang/customers/template/) should be replicated, either on a branch or new repository, to start your deployment. Follow the instructions in the [template's readme](https://repo1.dso.mil/big-bang/customers/template/-/tree/main/README.md) and in the [Big Bang docs](./docs) for configuration.

Follow the [Big Bang documentation](./docs) for testing a full deployment of Big Bang.

## DNS

To ease with local development, the TLD `dev.bigbang.mil` is maintained by the Platform One team with the CNAME record:

`CNAME: *.dev.bigbang.mil -> cluster.local`

All routable endpoints BigBang deploys will use the TLD of `bigbang.dev` by default. It is expected that consumers modify this appropriately for their environment.

## Secrets & Certificates

Follow instructions in the [Big Bang encryption guide](./docs/understanding-bigbang/concepts/encryption.md) for how to encrypt and decrypt secrets.

## Merge Requests Process

The merge request process is provided as an overview of the pipeline stages required to get a commit merged.

Follow instruction in [CI-Workflow](./docs/developer/ci-workflow.md) for specific details on the pipeline stages.

## Security Considerations

- To report a cybersecurity concern, follow this [link](https://jira.il2.dso.mil/servicedesk/customer/portal/81).
- Never push secrets or certificates into our repository.

- Big Bang does not recommend using internal databases for production deployments. Please look into having external databases, each application will have guides to deploy production system.

# Community Contributions to DoD-Platform-One via Github

## How to Contribute

1. Fork this repository, develop, and test your changes.
1. Submit a pull request.
1. Keep an eye out for comments. From bots and maintainers to ensure CI is passing and issues or suggestions are addressed.

### Technical Requirements

* Pipelines which must pass will run on runners from `repo1.dso.mil` and a bot will comment the status and information from the pipeline.
* Any change to a Big Bang package chart requires a version bump following [semver](https://semver.org/) principles. See [Documentation Changes](#documentation-changes) and [Versioning](#versioning) below
* Big Bang Package Issues which need to be included in the Big Bang Umbrella chart are not complete when the package PR is merged so please do not close issues. A new tag will automatically get created on `repo1.dso.mil` along with an MR into the Big Bang Umbrella as part of the CI process. This repo1 MR is reviewed the Big Bang Product team to merge on the Gitlab side, upon which the issue will be closed.
* Changes to the Big Bang Umbrella get released separately according to our Release Schedule outlined in the [README](./README.md#release-schedule).

Once changes have been merged, all subsequent automation will run on `repo1.dso.mil` with changes getting published back to Github.

### Documentation Changes

If your changes are to documentation or guides/images and not code, templates or variables then a `kind::docs` label will need to be added and will not kick off and wait for CI testing to complete.

### Versioning

Big Bang package chart `version` should follow [semver](https://semver.org/).

Charts should start at `1.0.0` unless they are based off an upstream chart (shown in chart/Kptfile) in which case a bug fix would increment the `bb.X` suffix.

Big Bang umbrella MRs will not need the version in `chart/Chart.yaml` edited via Pull Requests.

### Generate README

The readme of each Big Bang package chart can be re-generated with the following command: <https://repo1.dso.mil/big-bang/product/packages/gluon/-/blob/master/docs/bb-package-readme.md>.

Big Bang umbrella MRs will not need the main README.md edited via Pull Requests.
