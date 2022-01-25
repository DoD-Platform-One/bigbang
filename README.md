# Big Bang Pipeline Templates

This repository provides Gitlab CI templates and additional tools / dependencies to test Big Bang and its individual packages.

## Package CI Pipeline Infrastructure

The package pipeline CI infrastructure files included in this repo can be used within a gitlab CI pipeline
(via a gitlab runner) for any Big Bang package.

Two or more stages will be executed in the pipeline, which are detailed below.

### Conformance Tests (linting)

This stage executes the open source tool "conftest" to execute a set of commands and
application specific validation on the package. The common conformance policies are located in the "policies"
directory of this repository. These are Rego based policies. Additionally package specific policies will be
executed if there is a directory in the package repo named "policy".

### Functional Testing

Functional smoke tests are executed via Helm tests. This repo provides a Helm library (`bb-test-lib` folder) which can
be used to simplify implementation of Helm tests in your package. Currently two testing types are supported through the
library, scripts (for CLI testing - think bash, python, etc) and cypress (for UI testing). These two test types are
described below along with examples of how to implement them. NOTE: If your package can be interacted via a UI and a CLI
both test types should be included. By default UI tests run before CLI tests the way the library is written, but this
can be overridden as described below.

Tests will automatically be run by the pipeline, but if you wish to run them locally you will need to install the
package with the test values, then run `helm test {{HELMRELEASE_NAME}} -n {{HELMRELEASE_NAMESPACE}}` replacing the
variables with the proper values for your package (you can check the helmrelease name and namespace with `helm ls -A`).

#### Including the gluon helm test library

These pipelines run helm tests found in each package by means of the bigbang [gluon](https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/blob/master/docs/bb-tests.md) library chart.

To include the gluon helm test library, you need to add a dependency to the packages Chart.yaml, with the latest version
(latest version can be seen in [gluon/chart/Chart.yaml](https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/blob/master/chart/Chart.yaml#L10)):

```yaml
dependencies:
  - name: gluon
    version: "x.x.x" # See https://repo1.dso.mil/platform-one/big-bang/pipeline-templates/pipeline-templates/-/blob/master/bb-test-lib/Chart.yaml#L18 for latest
    repository: "oci://registry.dso.mil/platform-one/big-bang/apps/library-charts/gluon/gluon"
```

Then verify your helm version is up to date (OCI features are confirmed working on 3.5.2+). After that run:

```bash
export HELM_EXPERIMENTAL_OCI=1
helm dependency update chart
```

The gluon will now be pulled into the `chart/charts` folder as an archive.

**For more information on how to use this library see the [README](https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/blob/master/docs/bb-tests.md)**

### Release CI

When you tag a new release (must be a protected tag) the pipeline will run two additional stages, package (bundles
artifacts for docker images and git repos, uploads to S3) and release (hits the Gitlab API to publish a release with
artifact links). The artifacts are designed to be used for airgap installations. If you want to test out these stages
to verify changes or view the release CI process without creating a tag, make an MR and add the `test-ci::release`
label. The pipeline will run both stages, uploading to a "timed-disposal" S3 bucket and "dry-running" a release.

### Using the infrastructure in your package CI gitlab pipeline

The Package Pipeline template is used to execute a conformance (linting) stage and a functional test phase for
a package (application). This template (located in /pipelines/bigbang-package.yaml) is intended to be included in the
gitlab-ci.yml file of a package repo. The following code example can be placed in the gitlab-ci.yml file to include
the package pipeline template.

All variables are optional, but can provide additional flexibility for more complicated packages.

Make sure to also update the ref to the tagged version of the pipeline you want to use. Latest versions and changes can
always be found in the [CHANGELOG](./CHANGELOG.md).

```yaml
include:
  - project: "platform-one/big-bang/pipeline-templates/pipeline-templates"
    ref: "master"
    file: "/pipelines/bigbang-package.yaml"
# Optional
variables:
  RELEASE_NAME: "Pick a name for the package to release as, default is the repo name"
  PACKAGE_NAMESPACE: "Install package to a specific namespace, default is the repo name"
  PACKAGE_HELM_NAME: "Install via Helm with specific name, default is the repo name"
# Example:
# RELEASE_NAME: "Elasticsearch & Kibana"
# PACKAGE_NAMESPACE: "logging"
# PACKAGE_HELM_NAME: "logging-ek"
```

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
pipeline to run. This script should be added under `tests/wait.sh` and follow this format below. You will need to check
what sort of health status is available in the k8s object and update the jsonpath and if check accordingly.
The timeElapsed portion provides a timeout after 10 minutes. You should only need to update the two commented lines
below in most cases. Some projects may have more than one custom resource
(i.e. Elasticsearch has both elasticsearch and kibana) and in these situations you can add another resourceHealth line
and change the if check to verify both.

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
## Sandbox Pipeline Template

The sandbox pipeline template is a simple pipeline that allows the pipeline to run to completion even if there are
failures at any stage of the pipeline.   This allows for quicker debugging of issues with new packages.

