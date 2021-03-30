# Big Bang Pipeline Templates

The purpose of this repository is to provide templates that can be used in Gitlab CI pipelines to build 
containers used in CI pipelines and provide CI templates that can be included in CI pipelines to perform CI 
pipeline validation.

## Available Templates

- **app**: Generic application pipeline template
- **package-tests**: Generic package (app) pipeline that performs conformance and functionality tests on packages.

## App Package Template Description
### Available Jobs

- **build**: Builds container image
- **scan**: Performs vulnerability scan on image
- **promote**: Promotes container image in repository with release tag

#### Global

- **Variable list:**
  - \$DOCKERFILE_DIR : The directory holding the dockerfile
  - \$DOCKERFILE_NAME : The name of the dockerfile in the $DOCKERFILE_DIR

#### Build

##### Kaniko Build

- **Stage**: Build
- **Primary Task to extend**: Kaniko
- **Variable list:**
  - \$CI_REGISTRY : GitLab container registry name (auto populated)
  - \$CI_REGISTRY_IMAGE : Image name to be built. (auto populated)
  - \$CI_REGISTRY_PASSWORD : GitLab container registry password (auto populated)
  - \$CI_REGISTRY_USER : GitLab container registry username (auto populated)
  - \$CI_COMMIT_SHORT_SHA : 8 character SHA of the latest commit.  (auto populated)
  - \$DOCKERFILE_DIR : Global
  - \$DOCKERFILE_NAME : Global
  - \$IMAGE : Image name to be built.  Defaults to $CI_REGISTRY_IMAGE.
  - \$REGISTRY1 : Iron Bank container registry name
  - \$REGISTRY1_PASSWORD : Iron Bank container registry password (populated from group environmental variable)
  - \$REGISTRY1_USER : Iron Bank container registry username (populated from group environmental variable)
- **Description**: Uses [kaniko](https://github.com/GoogleContainerTools/kaniko) to build the described image from the repository

#### Scan

- **Stage**: Scan
- **Primary Task to extend**: Trivy
- **Variable list**:
  - \$CI_REGISTRY_IMAGE : Image name to be built. (auto populated)
  - \$CI_REGISTRY_PASSWORD : GitLab container registry password (auto populated)
  - \$CI_REGISTRY_USER : GitLab container registry username (auto populated)
  - \$CI_COMMIT_SHORT_SHA : 8 character SHA of the latest commit.  (auto populated)
  - \$IMAGE : Image name to be built.  Defaults to $CI_REGISTRY_IMAGE.
- **Description**:  Uses [trivy](https://github.com/aquasecurity/trivy) to scan the image for vulnerabilities.  The pipeline will not fail if vulnerabilities are found.

#### Promote

- **Stage**: Promote
- **Primary task to extend**: promote
- **Variable list**:
  - \$CI_REGISTRY_IMAGE : Image name to be built. (auto populated)
  - \$CI_REGISTRY_PASSWORD : GitLab container registry password (auto populated)
  - \$CI_REGISTRY_USER : GitLab container registry username (auto populated)
  - \$CI_COMMIT_SHORT_SHA : 8 character SHA of the latest commit.  (auto populated)
  - \$CI_COMMIT_TAG : Formal release tag for image consumption
  - \$IMAGE : Image name to be built.  Defaults to $CI_REGISTRY_IMAGE.
- **Description**:  Uses [skopeo](https://github.com/containers/skopeo) to copy the image tagged with the SHA to a formal commit tag.

### Pre-Defined Variables

The [Packages](https://repo1.dso.mil/platform-one/big-bang/apps) group has the following variables pre-configured:

| Variable Name | Purpose | Last updated |
|--|--|--|
| REGISTRY1_PASSWORD | Authenticate to Registry1 | 11/02/2020 |
| REGISTRY1_USERNAME | Authenticate to Registry1 | 11/02/2020 |

The Gitlab CI/CD auto injected variables [reference](https://docs.gitlab.com/ee/ci/variables/predefined_variables.html).

## Package Test CI Pipeline Infrastructure

The package pipeline CI infrastructure files included in this repo can be used in two different modes:
1) Within a gitlab CI pipeline (via a gitlab runner)
1) Within a local development environment (e.g., laptop or local computer)

Both modes will execute two stages:

### Conformance Tests (linting)
This stage executes the open source tool "conftest" to execute a set of commands and 
application specific validation on the package.   The common conformance policies are located in the "policies" 
directory of this repository.   These are Rego based policies.   Additionally package specific policies will be 
executed if there is a directory in the package repo named "policy".   

### Functional testing
Functional smoke tests can be executing using the cypress testing tool.  After conformance testing is performed, a 
small K3D cluster is created and any cypress tests located in the "tests" directory of the package will be executed. 

### Release CI
When you tag a new release (must be a protected tag) the pipeline will run two additional stages, package (bundles 
artifacts for docker images and git repos, uploads to S3) and release (hits the Gitlab API to publish a release with 
artifact links). The artifacts are designed to be used for airgap installations. If you want to test out these stages 
to verify changes or view the release CI process without creating a tag, make an MR and add the `test-ci::release` 
label. The pipeline will run both stages, uploading to a "timed-disposal" S3 bucket and "dry-running" a release.

### Using the infrastructure in your package CI gitlab pipeline

The Package Pipeline template is used to execute a conformance (linting) stage and a functional test phase for 
a package (application).   This template (located in templates/package-tests.yml) is intended to be included in the 
gitlab-ci.yml file of a package repo.  The following code example can be placed in the gitlab-ci.yml file to include 
the package pipeline template.

Make sure to update the `RELEASE_NAME` variable, it will be used in CI as the title for releases. This will default to the repo name.

Make sure to also update the ref to the tagged version of the pipeline you want to use. Latest versions and changes can always be found in the [CHANGELOG](./CHANGELOG.md).

```yaml
include:
  - project: 'platform-one/big-bang/pipeline-templates/pipeline-templates'
    ref: '1.0.0'
    file: '/templates/package-tests.yml'
# Optional
variables:
  RELEASE_NAME: "Pick a name for the package to release as"
  # Example:
  # RELEASE_NAME: "Elasticsearch & Kibana"
```

If the package has any dependencies that must be installed first (i.e. an operator) you will need to create a file 
in the package repo - `tests/dependencies.yaml` - with the following contents (note optional values):

- `dependencyname`: The top level for each dependency, name for it
- `git.repo`: This should be the direct link to clone the dependency repo, in quotes
- `git.tag`: Optional, pass in a specific tag (or technically branch) to clone the dependency from, will default to main
- `namespace`: Optional, pass in a namespace to install the dependency under (useful if the dependency needs to be installed under a specific namespace, i.e. gitlab-runners need to be in gitlab namespace), defaults to the dependency name (top level yaml) if not provided

Structure these values in your yaml file as follows:

```yaml
dependencyname:
  git:
    repo: "Git repo clone URL"
    tag: "Tag to clone from"
  namespace: "Namespace to install in"
# Example
opa:
  git:
    repo: "https://repo1.dsop.io/platform-one/big-bang/apps/core/policy.git"
    tag: "1.1.0-bb.0"
  namespace: "gatekeeper-system"
```

If the package makes use of an operator and creates custom resources it is best to create a custom wait script for the pipeline to run. 
This script should be added under `tests/wait.sh` and follow this format below. You will need to check what sort of health status is available 
in the k8s object and update the jsonpath and if check accordingly. The timeElapsed portion provides a timeout after 10 minutes. You should 
only need to update the two commented lines below in most cases. Some projects may have more than one custom resource (i.e. Elasticsearch has 
both elasticsearch and kibana) and in these situations you can add another resourceHealth line and change the if check to verify both.

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

### Using the CI pipline infrastrcuture to test packages locally

This repo also contains the infrastructure and scripts needed to execute the above described stages in a local environment.
This infrastructure is located in the "local-dev" directory of this repository and documented in the README.md file located there.
