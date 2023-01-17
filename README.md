# Big Bang Pipeline Templates

This repository provides Gitlab CI templates and additional tools / dependencies to test Big Bang and its individual packages.

&nbsp;

## Setting Up Your Project with Pipelines

Please refer to this Big Bang developer [doc](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/docs/developer/package-integration/pipeline.md) to enable and configure pipelines for your Big Bang project

&nbsp;

## Package CI Pipeline Infrastructure

The package pipeline CI infrastructure files included in this repo can be used within a GitLab CI pipeline
(via a gitlab runner) for any Big Bang package.

Two or more stages will be executed in the pipeline, which are detailed below.

&nbsp;

### Functional Testing

Functional smoke tests are executed via [Helm tests](https://helm.sh/docs/topics/chart_tests/).

We use an internally developed [Helm library chart](https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon) which can
be used to simplify implementation of Helm tests in your package.

Currently two testing types are supported in the library:

- Script tests (Bash, Python, etc)

- [Cypress](https://www.cypress.io/) for UI testing.

These two test types are described below along with examples of how to implement them.

NOTE: If your package can be interacted via a UI and a CLI
both test types should be included.

By default, UI tests execute before CLI tests, but this
can be overridden as described below.

Tests will automatically be run by the pipeline, but if you wish to run them locally, you can follow the steps listed below:

- Create a Kubernetes cluster. For quick, local development, you can use tools such as [kind](https://kind.sigs.k8s.io/) or [k3d](https://k3d.io)

- From the root of your package repository, install your package with your test values. This will install your package in the `default` namespace of your Kubernetes cluster

```bash
helm install my-release chart/ --values tests/test-values.yaml
```

- Execute the Helm tests

```bash
helm test my-release
```

#### Including the Gluon Helm Test Library in Your Package

Big Bang pipelines run helm tests found in each package by means of the Big Bang [gluon](https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/blob/master/docs/bb-tests.md) library chart

To include the gluon helm test library, you need to add a dependency to your package's Chart.yaml file

The latest version can be found [here](https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/blob/master/chart/Chart.yaml#L10)

```yaml
dependencies:
  - name: gluon
    version: "x.x.x"
    repository: "oci://registry1.dso.mil/bigbang"
```

The gluon chart is packaged and released as an [OCI artifact](https://helm.sh/docs/topics/registries/)

We recommend using `helm` v3.8.0 or newer to eliminiate potential issues with OCI artifacts

```bash
helm dependency update chart
```

The gluon chart will now be pulled into the `chart/charts` folder as an archive.

**For more information on how to use this library see this [doc](https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/blob/master/docs/bb-tests.md)**

&nbsp;

### Release CI

When you tag a new release (must be a protected tag) the pipeline will run two additional stages:

- package (bundles artifacts for docker images and git repos, uploads to S3)

- release (hits the Gitlab API to publish a release with
artifact links)

The artifacts are designed to be used for airgap installations.

If you want to test out these stages
to verify changes or view the release CI process without creating a tag, create a merge request and add the `test-ci::release`
label.

The pipeline will run both stages, uploading to a "timed-disposal" S3 bucket and "dry-running" a release

&nbsp;

### Dependencies

If the package has any dependencies that must be installed first (i.e. an operator) you will need to create a file
in the package repo - `tests/dependencies.yaml` - with the following contents (note optional values):

- `dependencyname`: The top level for each dependency, name for it
- `git.repo`: This should be the direct link to clone the dependency repo, in quotes
- `git.tag`: Optional, pass in a specific tag (or technically branch) to clone the dependency from, will default to main
- `namespace`: Optional, pass in a namespace to install the dependency under (useful if the dependency needs to be
  installed under a specific namespace, i.e. gitlab-runners need to be in gitlab namespace), defaults to the dependency
  name (top level yaml) if not provided
- `package-name`: Optional, pass in a specific name for the dependency to be installed as via Helm. Can be helpful to
  match the HelmRelease names at the top Big Bang level. Defaults to the dependency name (top level yaml) if not provided.

Structure these values in your yaml file as follows:

```yaml
dependencyname:
  git:
    repo: "Git repo clone URL"
    tag: "Tag to clone from"
  namespace: "Namespace to install in"
  package-name: "Name of the Helm release"

# Example
opa:
  git:
    repo: "https://repo1.dsop.io/platform-one/big-bang/apps/core/policy.git"
    tag: "1.1.0-bb.0"
  namespace: "gatekeeper-system"
  package-name: "gatekeeper"
```

If the package makes use of an operator and creates custom resources it is best to create a custom wait script for the
pipeline to run.

This script should be added under `tests/wait.sh` and follow this format below:

```bash
#!/bin/sh
wait_project() {
   timeElapsed=0
   while true; do
      resourceHealth=$(kubectl get RESOURCE -A -o jsonpath='{.items[0].status.health}' | xargs)     # Update with the resource to check and jsonpath
      if [[ $resourceHealth == "DESIREDHEALTH" ]]; then                                             # Update with desired health/output of the jsonpath
         break
      fi
      sleep 5
      timeElapsed=$(($timeElapsed+5))
      if [[ $timeElapsed -ge 600 ]]; then
         exit 1
      fi
   done
}
```

You will need to check what sort of health status is available in the k8s object and update the jsonpath to check accordingly.

The timeElapsed portion provides a timeout after 10 minutes. In most cases, you should only need to update the two commented lines
in the script above.

Some projects may have more than one custom resource (i.e. Elasticsearch has both elasticsearch and kibana) and in these situations you can add another `resourceHealth` line
and change the `if` check to verify both.

&nbsp;

### Policy Validation

The following pipelines execute a series of tests against [Kyverno](https://kyverno.io/) policies:
- bigbang-package
- sandbox
- third-party

The script located at `scripts/policies/kyverno_policy_tests.sh` contains the logic for these tests.

This is performed as a linting operation prior to any resources being installed onto a Kubernetes cluster.

Big Bang package helm charts are templated out into raw YAML manifests using `helm template` and `kyverno apply` is used to execute the validation policies against these Kubernetes resources prior to being installed onto a cluster.

There are two functions in the script that will be executed for policy validation:

- `global_policy_tests`
  - Applies the policies located in the [kyverno-policies Big Bang package repo](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/kyverno-policies/-/tree/main/chart/templates) against Big Bang packages.

- `package_policy_tests`
  - Applies package-specific policies located in the `tests/policy` directory of a Big Bang package repository if it exists.

&nbsp;

## Sandbox Pipeline Template

The sandbox pipeline template is a simple pipeline that allows the pipeline to run to completion even if there are
failures at any stage of the pipeline.   This allows for quicker debugging of issues with new packages.

&nbsp;

# Testing Changes To The Pipelines

#### Testing A Package With Your CI Contributions

To test your package against any pipeline contributions you've made, you will need to reach out to the administrator of your project repository to edit the GitLab CI/CD settings to point to your branch.

&nbsp;

#### Testing Big Bang With Your CI Contributions

To test Big Bang against any pipeline contributions you've made, you can simply configure the `.gitlab-ci.yml` as shown below:

```yaml
include:
  - project: 'platform-one/big-bang/pipeline-templates/pipeline-templates'
    ref: <my_branch>
    file: '/pipelines/bigbang.yaml'
variables:
  PIPELINE_REPO_BRANCH: <my_branch>
```

&nbsp;

## MR Title Keywords

To easily adjust the pipeline behavior without a commit, keywords can be placed in the title of Merge Requests.

Supported keywords:

`DEBUG` -- Enables debug mode. This will set -x in shell scripts so each command is printed before it runs, and dumps information such as the networking configuration (virtual services, gateways, dns, /etc/hosts files), cluster information (kustomize, cluster resources, memory and cpu usage), and dumps the cluster logs.

`SKIP UPGRADE` -- Skips the upgrade test stage of a pipeline.

`SKIP UPDATE CHECK` -- Skips the check in the configuration validation stage to see if the chart version was incremented.

`SKIP INTEGRATION` -- Skips the integration stage which is used in the third-party and sandbox pipelines.

&nbsp;

### MR Labels

Similar to the MR title keywords described above, gitlab labels can be added to Merge Requests to adjust CI pipeline behavior.

##### Labels for bigbang MRs
`all-packages` -- Enables all bigbang packages. This will typically cause the cluster to run slower due to the increased resource usage, so it can be helpful in making sure any timeouts you've set aren't too short or check for any conflicts between packages, etc.

`<package-name>` -- Adding a package name as a label will enable that package.

`test-ci::infra` -- Add stages to provision and destroy the cloud infrastructure where the tests will run.

`test-ci::airgap` -- Add stages to provision and destroy a simulated airgap bb install.

##### Labels for bigbang and package MRs
`test-ci::release` -- Test the release CI, which includes the package and release stages.

`disable-ci` -- Disables all pipeline runs.

`kind::docs` -- For MRs with only document changes. Won't run any pipelines.

`skip-bb-mr` -- Will skip the auto-creation of a merge request into bigbang.
