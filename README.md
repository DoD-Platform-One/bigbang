# Big Bang Pipeline Templates

## Available Templates

## Available Jobs

### Build

#### Trivy Build

- Stage: Build
- Primary Task to extend: Kaniko
- Variable list
  - $CI_REGISTRY_IMAGE : Gitlab variable auto populated
  - $CI_COMMIT_SHORT_SHA : 8 character sha of the latest commit, Gitlab variable auto populated 
  - $IMAGE : The name of the image to be built
  - $DOCKERFILE_DIR: The directory the dockerfile is, should be root
  - $DOCKERFILE_NAME: The name of the docker file in the $DOCKERFILE_DIR
  - $DOCKER_AUTH: The authentication file used to connect to base image repository
- Description: uses [Kaniko](https://github.com/GoogleContainerTools/kaniko) to build the described image from the repository

### Promote

### Scan


## Expected Variables

The [Big Bang](https://repo1.dsop.io/platform-one/private/big-bang) project has the following variables configured

| Variable Name     | Purpose                       | Last updated      |
|--------------     | --------                      | ------------      |
| DOCKER_AUTH       | Authenticate to Registry1     | 10/14/2020        |
