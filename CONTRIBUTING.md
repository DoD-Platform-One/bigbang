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
  - [Iron Bank Images](#iron-bank-images)
  - [Local Kubernetes cluster](#local-kubernetes-cluster)
  - [Deploying Big Bang (Quick Start)](#deploying-big-bang-quick-start)
  - [Testing Big Bang Development Changes](#testing-big-bang-development-changes)
  - [DNS](#dns)
  - [Secrets & Certificates](#secrets--certificates)
  - [Merge requests process](#merge-requests-process)
    - [Pipeline Stages](#pipeline-stages)
      - [Linting](#linting)
      - [Smoke Testing](#smoke-testing)
      - [Infrastructure Testing](#infrastructure-testing)
        - [Network Creation](#network-creation)
        - [Cluster(s) Creation](#clusters-creation)
        - [Big Bang Installation](#big-bang-installation)
        - [Big Bang Tests](#big-bang-tests)
      - [Teardown](#teardown)

## Developers Guide 

Big Bang is designed in such a way as to be as easily deployed locally as it is in production.  In fact, most contributions begin locally.

## Local Git Setup

### Pre-commit hooks

We would like developers to leverage [conventional commits](https://www.conventionalcommits.org/) when contributing. In order to help enforce this we are leveraging client-side pre-commit hooks. This is done using the following tools:

- [husky](https://www.npmjs.com/package/husky)
- [commitlint](https://commitlint.js.org/#/)

#### Local Setup

##### Prereqs

- Install [npm](https://www.npmjs.com/get-npm)

##### Steps

After cloning this git repo run the following command:

```bash
npm install --only=dev
```

This will download `husky` and `commitlint` to your local repo and modify your `.git/hooks` to allow husky to run pre-commit hooks. Once installed it will enforce the usage of convential-commits.

## Iron Bank Images

Per the [charter](https://repo1.dsop.io/platform-one/big-bang/charter), all Big Bang packages will leverage container images from [IronBank](https://ironbank.dsop.io/).  In order to pull these images, ImagePullSecrets must be provided to BigBang.  To obtain access to these images, follow the guides below.  These steps should NOT be used for production since the API keys for a user are only valid when the user is logged into [Registry1](https://registry1.dsop.io)

1) Register for a free Ironbank account [Here](https://sso-info.il2.dsop.io/new_account.html)
1) Log into the [Iron Bank Registry](https://registry1.dsop.io), in the top right click your *Username* and then *User Profile* to get access to your *CLI secret*/API keys.
1) When installing BigBang, set the Helm Values `registryCredentials.username` and `registryCredentials.password` to match your Registry1 username and API token

## Local Kubernetes cluster

Follow the steps below to get a local Kubernetes cluster for Big Bang  using [k3d](https://k3d.io/).

```bash
# Create a local k3d cluster with the appropriate port forwards
k3d cluster create --k3s-server-arg "--disable=traefik" --k3s-server-arg "--disable=metrics-server" -p 80:80@loadbalancer -p 443:443@loadbalancer
```

## Deploying Big Bang (Quick Start)

For development, it is quicker to test changes without having to push to Git.  To do this, we can bypass Flux2 and deploy Big Bang directly with its Helm chart.

Start by creating `myvalues.yaml` to configure your local Big Bang.  Big Bang's template repository contains a starter [development values.yaml](https://repo1.dsop.io/platform-one/big-bang/customers/template/-/blob/main/dev/configmap.yaml).

Configure `myvalues.yaml` to suit your needs.

```bash
# Deploy the latest fluxv2 with Iron Bank images
# For development, you can use flux from the internet using 'flux install`
# Be aware, the internet version is likely newer than the Iron Bank version
./hack/flux-install.sh

# Apply a local version of the umbrella chart
# NOTE: This is the alternative to deploying a HelmRelease and having flux manage it, we use a local copy to avoid having to commit every change
helm upgrade -i bigbang chart -n bigbang --create-namespace -f myvalues.yaml

# A convenience development script is provided to force fluxv2 to reconcile all helmreleases within the cluster insteading of waiting for the next polling interval.
hack/sync.sh
```

For more extensive development, use the [Development Guide](docs/c_development.md).

## Testing Big Bang Development Changes

Development changes should be tested using a full GitOps environment.  The [Big Bang environment template](https://repo1.dsop.io/platform-one/big-bang/customers/template/) should be replicated, either on a branch or new repository, to start your deployment.  Follow the instructions in the [template's readme](https://repo1.dsop.io/platform-one/big-bang/customers/template/-/tree/main/README.md) and in the [Big Bang docs](./docs) for configuration.

Follow the [Big Bang documentation](./docs) for testing a full deployment of Big Bang.

## DNS

To ease with local development, the TLD `bigbang.dev` has been purchased with the following CNAME record:

`CNAME: *.bigbang.dev -> 127.0.0.1`

All routable endpoints BigBang deploys will use the TLD of `bigbang.dev` by default.  It is expected that consumers modify this appropriately for their environment.

## Secrets & Certificates

A __development only__ gpg key is provided at `bigbang-dev.asc` that is used to encrypt and decrypt the secrets in this Git repository (e.g. [hack/secrets](hack/secrets/).

We cannot stress enough, __do not use this key to encrypt real secret data__.  It is a shared key meant to demonstrate the workflow of secrets management within Big Bang.

Follow instructions in the [Big Bang encryption guide](docs/3_encryption.md) for how to encrypt and decrypt secrets.

## Merge requests process

The following is meant to serve as an overview of the pipeline stages required to get a commit merged.

### Pipeline Stages

The pipeline is split into several stages:

#### Linting

Several linting rules are first run to ensure yaml standards are met within the primary `./charts` folder.

This stage is ran on every commit, and is a requirement for merging.

#### Smoke Testing

For fast feedback testing, an ephemeral in cluster pipeline is created using [`k3d`](https://k3d.io) that lives for the lifetime of the gitlab ci job.  Within that cluster, BigBang is deployed, and an initial set of smoke tests are performed against the deployment to ensure basic conformance.

This stage verifies several easy to check assumptions such as:

- does BigBang successfully install
- does BigBang successfully upgrade (from master)
- are endpoints routable

This stage also serves as a guide for local development, and care is taken to ensure all pipeline actions within this stage are repeatable locally.

This stage is ran on every commit, and is a requirement for merging.

#### Infrastructure Testing

Ultimately, BigBang is designed to deploy production ready workloads on real infrastructure.  While local and ephemeral clusters are excellent for fast feedback during development, changes must ultimately be tested on real clusters on real infrastructure.

As part of BigBang's [charter](https://repo1.dsop.io/platform-one/big-bang/charter), it is expected work on any CNCF conformant kubernetes cluster, on multiple clouds, and on premise environments.  By very definition, this means infrastructure testing is _slow_.  To strive for a pipeline with a happy medium of providing fast feedback while still exhaustively testing against environments that closely mirror production, __infrastructure testing only occurs on manual actions on merge request commits.__

When you are comfortable your branch is ready to be merged, opening up an merge request will trigger the creation of a suite of infrastructure testing jobs which will require a manual action from a project maintainer (assuming previous linting and smoke tests have passed).  Once the commit(s) are validated against the infrastructure tests, your changes are ready to be merged!

For _most_ of the infrastructure testing, `terraform` is chosen as the IAC tool of choice for infrastructure that BigBang owns, while the cluster creation process follows the vendors recommended installation process.

The infrastructure pipeline is designed to have _no_ human interaction, and are scoped to the lifecycle of the pipeline.  This means a single pipeline is fully responsible for provisioning infrastructure, but just as important, deprovisioning infrastructure, ensuring resources are not orphaned.

More information on the full set of infrastructure tests are below:

##### Network Creation

For each cloud, a BigBang owned network will be created that conform with the appropriate set of tests about to be ran.  For example, to validate that Big Bang deploys in a connected environment on AWS, a VPC, subnets, route tables, etc... are created, and the outputs are made available through terraform's remote `data` source.

##### Cluster(s) Creation

Several types of clusters are created within the previously provisioned network(s), and follow the vendors recommended iac approach.

For example, an `rke2` cluster is created that leverages the upstream [terraform modules](https://repo1.dsop.io/platform-one/distros/rancher-federal/rke2/rke2-aws-terraform), and an `eks` cluster is created with the upstream [terraform modules](https://docs.microsoft.com/en-us/azure/developer/terraform/create-k8s-cluster-with-tf-and-aks).

It is a hard requriement at this stage that every cluster outputs an admin scoped `kubeconfig` as a gitlab ci artifact.  This artifact will be leveraged in the following stages for interacting with the created cluster.

##### Big Bang Installation

Given the kubeconfig created in the previous stage, BigBang is installed on the cluster using the same installation process used in the smoke tests.

Like any BigBang installation, several cluster requirements (TODO: doc these) must be met before BigBang is installed, and it is up to the vendor to ensure those requirements are met.

##### Big Bang Tests

Assuming BigBang has installed successfully, additional tests residing within the `./tests` folder of this repository are run against the deployed cluster.  These tests range from automated UI testing, to internal kubernetes resource validation and verification.

TODO: Document these tests more once they are flushed out.

#### Teardown

Infrastructure teardown happens in the reverse sequence as to which they are deployed, and the pipeline will ensure these teardown jobs are _always_ ran, regardless of whether or not the previous jobs were successful.

Combined with terraform's declarative remote state, the "always on" teardown ensures no orphaned resources are left over once tests are run.

Within the teardown process, the commit scoped terraform workspace is also deleted to ensure the remote state remains clean.

For example, if an EKS cluster fails to provision, a full teardown of BigBang, EKS, and the network will be run, even though BigBang was never deployed.  This will result in 2 failing jobs (EKS up and BigBang down), but will ensure that no infrastructure resources become orphaned.
