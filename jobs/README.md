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
