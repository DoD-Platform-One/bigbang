# Contributing to Big Bang

Thanks for taking the time to contribute to BigBang!

## Developers Guide

Big Bang is designed in such a way as to be as easily deployed locally as it is in production.  In fact, most contributions begin locally.

Follow the steps below to get a complete local instantiation of Big Bang up locally using [k3d]().

### Local Development Quickstart

#### Local `k3d` cluster

```bash
# Create a local k3d cluster with the appropriate port forwards
k3d cluster create --k3s-server-arg "--disable=traefik" --k3s-server-arg "--disable=metrics-server" -p 80:80@loadbalancer -p 443:443@loadbalancer
```

#### Deploying Big Bang

Several examples are provided under the `./examples` folder that run through various implementations of BigBang.

```bash
# Deploy the latest fluxv2 with iron bank images
flux install --registry registry.dsop.io/platform-one/big-bang/apps/sandbox/fluxv2 --timeout 3m0s

# Apply a local version of the umbrella chart
# NOTE: This is the alternative to deploying a HelmRelease and having flux manage it, we use a local copy to avoid having to commit every change
# NOTE: Use yq to parse the kustomize values patch and pipe it to the helm values
yq r examples/complete/envs/dev/patch-bigbang.yaml 'spec.values' | helm upgrade -i bigbang chart -n bigbang --create-namespace -f -

# Apply the necessary dev secrets
# NOTE: You should do this immediately after the previous helm command in case there are any secrets that the helm charts require to boot
# NOTE: Flux will take care of the reconcilitation and retry loops for us, it is normal to see resources fail to deploy a few times on boot
kubectl apply -f examples/complete/envs/dev/source-secrets.yaml

# After making changes to the umbrella chart or values, you can update the chart idempotently
yq r examples/complete/envs/dev/patch-bigbang.yaml 'spec.values' | helm upgrade -i bigbang chart -n bigbang --create-namespace -f -

# A convenience development script is provided to force fluxv2 to reconcile all helmreleases within the cluster
hack/sync.sh
```

#### DNS

To ease with local development, the TLD `bigbang.dev` has been purchased with the following CNAME record:

`CNAME: *.bigbang.dev -> 127.0.0.1`

All routable endpoints BigBang deploys will use the TLD of `bigbang.dev` by default.  It is expected that consumers modify this appropriately for their environment.

#### Secrets & Certificates

A __development only__ gpg key is provided at `bigbang-dev.asc` that is used to encrypt and decrypt the "secret" information in `envs/dev/secrets`.

We cannot stress enough, __do not use this key to encrypt real secret data__.  It is a shared key meant to demonstrate the workflow of secrets management within Big Bang.

```bash
# Import the gpg key
gpg --import bigbang-dev.asc

# Decrypt the Big Bang Development Wildcard Cert
sops -d envs/dev/secrets/ingress-cert.yaml

# Encrypt the Big Bang Development Wildcard Cert
sops -e envs/dev/secrets/ingress-cert.yaml
```

## Merge requests process

The following is meant to serve as an overview of the pipeline stages required to get a commit merged.

### Pipeline Stages

The pipeline is split into several stages:

#### Linting

Several linting rules are first run to ensure yaml standards are met within the primary `./charts` folder.

This stage is ran on every commit, and is a requirement for merging.

#### Smoke Testing

For fast feedback testing, an ephemeral in cluster pipeline is created using [`k3d`]() that lives for the lifetime of the gitlab ci job.  Within that cluster, BigBang is deployed, and an initial set of smoke tests are performed against the deployment to ensure basic conformance.

This stage verifies several easy to check assumptions such as:

* does BigBang successfully install
* does BigBang successfully upgrade (from master)
* are endpoints routable

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