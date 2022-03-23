# Gitlab-ci Workflow

The following is meant to serve as an overview of the pipeline stages required to get a commit merged. There are package, bigbang, and infrastructure pipelines.

[[_TOC_]]

## Generic Package Pipeline Stages

This pipeline is triggered by the following for individual bigbang packages:

- merge request events
  - Note: Currently upgrade step only runs during MR events
- manual tag events
- commits to default branch

![Package Pipeline](imgs/Package_pipeline.png)

[Link to draw.io diagram file](diagrams/BB_gitlab_ci_diagram.drawio). This diagram file should be modified on draw.io and exported into this repository when the developer / ci workflow changes. It is provided here for ease of use.

### Configuration Validation

This stage runs a `helm conftest` which is a plugin for testing helm charts with Open Policy Agent. It provides the following checks:

- confirms that the helm chart is valid (should fail similar to how a helm lint fails if there is bad yaml, etc)
- runs the helm chart against a set of rego policies - currently these tests will only raise warnings on "insecure" things and will allow pipeline to proceed.

### Package Tests

This stage verifies several easy to check assumptions such as:

- does package successfully install
- does package successfully upgrade (from master)
- package specific tests

If required, the upgrade step can skipped when MR title starts with 'SKIP UPGRADE'

## BigBang Pipeline Stages

This pipeline is triggered by the following for individual bigbang packages:

- merge request events
  - Note: Currently upgrade step only runs during MR events
- manual tag events
- commits to default branch

The pipeline is split into several stages:

![BB Pipeline](imgs/BB_pipelines.png)

[Link to draw.io diagram file](diagrams/BB_gitlab_ci_diagram.drawio). This diagram file should be modified on draw.io and exported into this repository when the developer / ci workflow changes. It is provided here for ease of use.

### Pre Vars

This stage currently has one purpose at this point which is to generate a terraform var.

### Smoke Tests

For fast feedback testing, an ephemeral in cluster pipeline is created using [`k3d`](https://k3d.io) that lives for the lifetime of the gitlab ci job.  Within that cluster, BigBang is deployed, and an initial set of smoke tests are performed against the deployment to ensure basic conformance.

This stage verifies several easy to check assumptions such as:

- does BigBang successfully install
- does BigBang successfully upgrade (from master)
- are endpoints routable

This stage will fail if:

- script failures
- gitrepositories status condition != ready
- expected helm releases are not present
- helm releases fail or timeout
- kustomization secrets are not ready or timeout
- deployments status condition != ready
- jobs status condition != complete
- statefulsets/daemonsets not 100% ready (ex. 0/1)
- any virtual service endpoints are not accessible

This stage also serves as a guide for local development, and care is taken to ensure all pipeline actions within this stage are repeatable locally.

This stage is ran on every merge request event, and is a requirement for merging.

## Infrastructure Testing Pipeline Stages

Ultimately, BigBang is designed to deploy production ready workloads on real infrastructure.  While local and ephemeral clusters are excellent for fast feedback during development, changes must ultimately be tested on real clusters on real infrastructure.

As part of BigBang's [charter](https://repo1.dso.mil/platform-one/big-bang/charter), it is expected work on any CNCF conformant kubernetes cluster, on multiple clouds, and on premise environments.  By very definition, this means infrastructure testing is _slow_.  To strive for a pipeline with a happy medium of providing fast feedback while still exhaustively testing against environments that closely mirror production, __infrastructure testing only occurs on manual actions on merge request commits.__
This requires adding `test-ci::infra` label to your MR. In addition, infrastructure testing pipeline is run nightly on a schedule.

Note: Due to the amount of resources and time required for this pipeline, the `test-ci::infra` label should be used sparingly. The scheduled nightly run will ideally catch issues if they are already in master. The `test-ci::infra` label should mainly be used when:

- your changes affect the infra ci
- your changes are large in scope and likely to behave differently on "real" clusters

When you are comfortable your branch is ready to be merged, opening up an merge request will trigger the creation of a suite of infrastructure testing jobs which will require a manual action from a project maintainer (assuming smoke tests have passed).  Once the commit(s) are validated against the infrastructure tests, your changes are ready to be merged!

For _most_ of the infrastructure testing, `terraform` is chosen as the IAC tool of choice for infrastructure that BigBang owns, while the cluster creation process follows the vendors recommended installation process.

The infrastructure pipeline is designed to have _no_ human interaction, and is scoped to the lifecycle of the pipeline.  This means a single pipeline is fully responsible for provisioning infrastructure, but just as important, deprovisioning infrastructure, ensuring resources are not orphaned.

More information on the full set of infrastructure tests are below:

![Infra Pipeline](imgs/Infra_test_pipelines.png)

[Link to draw.io diagram file](diagrams/BB_gitlab_ci_diagram.drawio). This diagram file should be modified on draw.io and exported into this repository when the developer / ci workflow changes. It is provided here for ease of use.

### Network Creation

For each cloud, a BigBang owned network will be created that conform with the appropriate set of tests about to be ran.  For example, to validate that Big Bang deploys in a connected environment on AWS, a VPC, subnets, route tables, etc... are created, and the outputs are made available through terraform's remote `data` source.

At this time the infrastructure testing pipeline is only utilizing internet-connect AWS govcloud.

### Cluster Creation

The infrastructure pipeline is currently setup to standup an `rke2` cluster by default.

An `rke2` cluster is created that leverages the upstream [terraform modules](https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-aws-terraform)

It is a hard requirement at this stage that every cluster outputs an admin scoped `kubeconfig` as a gitlab ci artifact.  This artifact will be leveraged in the following stages for interacting with the created cluster.

### Big Bang Installation

Given the kubeconfig created in the previous stage, BigBang is installed on the cluster using the same installation process used in the smoke tests.

Like any BigBang installation, several cluster requirements (see [Pre-requisites](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/tree/master/docs/guides/prerequisites)) must be met before BigBang is installed, and it is up to the vendor to ensure those requirements are met.

### Big Bang Tests

Assuming BigBang has installed successfully, additional tests residing within the `./tests` folder of this repository are run against the deployed cluster.

Currently there are 3 test scripts that test the following:

- wait for resources to be ready, ensures everything goes to running at a kubernetes level
- curl VirtualService endpoints, to validate istio works + the UIs are up
- fetch a list of non-IB images (this test never fails but provides some contextual info)

### Teardown

Infrastructure teardown happens in the reverse sequence as to which they are deployed, and the pipeline will ensure these teardown jobs are _always_ ran, regardless of whether or not the previous jobs were successful.

Combined with terraform's declarative remote state, the "always on" teardown ensures no orphaned resources are left over once tests are run.

Within the teardown process, the commit scoped terraform workspace is also deleted to ensure the remote state remains clean.

For example, if an RKE2 cluster fails to provision, a full teardown of BigBang, RKE2, and the network will be run, even though BigBang was never deployed.  This will result in 2 failing jobs (RKE2 up and BigBang down), but will ensure that no infrastructure resources become orphaned.
