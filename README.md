# Big Bang Pipeline Templates

This repository provides Gitlab CI templates and additional tools / dependencies to test Big Bang packages.

## Package Test CI Pipeline Infrastructure

The package pipeline CI infrastructure files included in this repo can be used within a gitlab CI pipeline (via a gitlab runner) for any Big Bang package.

Two or more stages will be executed in the pipeline, which are detailed below.

### Conformance Tests (linting)
This stage executes the open source tool "conftest" to execute a set of commands and 
application specific validation on the package.   The common conformance policies are located in the "policies" 
directory of this repository.   These are Rego based policies.   Additionally package specific policies will be 
executed if there is a directory in the package repo named "policy".   

### Functional Testing
Functional smoke tests are executed via Helm tests. This repo provides a Helm library (`bb-test-lib` folder) which can be used to simplify implementation of Helm tests in your package. Currently two testing types are supported through the library, scripts (for CLI testing - think bash, python, etc) and cypress (for UI testing). These two test types are described below along with examples of how to implement them. NOTE: If your package can be interacted via a UI and a CLI both test types should be included. By default UI tests run before CLI tests the way the library is written, but this can be overridden as described below.

Tests will automatically be run by the pipeline, but if you wish to run them locally you will need to install the package with the test values, then run `helm test {{HELMRELEASE_NAME}} -n {{HELMRELEASE_NAMESPACE}}` replacing the variables with the proper values for your package (you can check the helmrelease name and namespace with `helm ls -A`).

#### Including the test library

To include the test library, you need to add a dependency to the packages Chart.yaml, with the latest version (0.4.0 as of this doc, latest version can be seen in `bb-test-lib/Chart.yaml`):

```yaml
dependencies:
  - name: bb-test-lib
    version: "0.4.0"
    repository: "oci://registry.dso.mil/platform-one/big-bang/pipeline-templates/pipeline-templates"
```

Then verify your helm version is up to date (OCI features are confirmed working on 3.5.2+). After that run:
```bash
export HELM_EXPERIMENTAL_OCI=1
helm dependency update chart
```

The bb-test-lib will now be pulled into the `chart/charts` folder as an archive.

#### Cypress

To include the Helm test templates for Cypress you will need to make a file under `chart/templates/tests` which includes the content below:

```yaml
{{- include "bb-test-lib.cypress-configmap.base" . }}
---
{{- include "bb-test-lib.cypress-runner.base" . }}
```

This will work for a "base" install, but if you want to override anything (example below shows how to add labels), you can include different templates and create package specific templates with the overrides:
```yaml
{{- include "bb-test-lib.cypress-configmap.overrides" (list . "mattermost-test.cypress-configmap") }}
{{- define "mattermost-test.cypress-configmap" }}
metadata:
  labels:
    {{ include "mattermost.labels" . | nindent 4 }}
{{- end }}
---
{{- include "bb-test-lib.cypress-runner.overrides" (list . "mattermost-test.cypress-runner") -}}
{{- define "mattermost-test.cypress-runner" -}}
metadata:
  labels:
    {{ include "mattermost.labels" . | nindent 4 }}
{{- end }}
```

The second step to implementing these tests will be including values in your `test-values.yaml` file that would be needed for the tests. There are 3 main values you will want to consider, all values are optional:
- `bbtests.cypress.artifacts`: This should be set to true in almost all cases so that artifacts are exported from the helm test pods and available as artifacts in the pipeline. This also provides them when running locally (a script is at `local-dev/scripts/cypress-artifacts.sh` that will get them in the proper format after helm tests run)
- `bbtests.cypress.secretEnvs`: This is where you should put any configuration that your tests need from secrets that are created by the helm chart (common examples are passwords) - Helm templating is supported here with proper syntax (braces must be wrapped in quotes, any quotes inside braces must be escaped)
- `bbtests.cypress.envs`: This is where any configuration that is not in pre-existing secrets should go (common examples are the service name to hit and usernames) - Helm templating is also supported here with the same restrictions of syntax. While you may be able to place ENVs into your `cypress.json`, that will not support Helm templating, which is the major benefit of using values for ENVs.

A sample is included below:
```yaml
bbtests:
  cypress:
    artifacts: true
    envs:
      HOST: "{{ .Values.service.port }}"
      MINIO_HOST: "{{ include \"minio.serviceName\" . }}"
      cypress_url: "http://{{ include \"minio.serviceName\" . }}:{{ .Values.service.port }}"
    secretEnvs:
      - name: cypress_secretkey
        valueFrom:
          secretKeyRef:
            name: "{{ .Values.minioRootCreds }}"
            key: secretkey
      - name: cypress_accesskey
        valueFrom:
          secretKeyRef:
            name: "{{ .Values.minioRootCreds }}"
            key: accesskey
```
NOTE: ENVs must be prefixed with `cypress_` to be available to Cypress.

Finally, a `cypress.json` file and all `*.spec.js` tests must be placed at the same directory level `chart/tests/cypress/`. Your `cypress.json` should follow the traditional cypress format, an example is included below:
```json
{
  "pluginsFile": false,
  "supportFile": false,
  "fixturesFolder": false,
  "baseUrl": "http://mattermost.mattermost.svc.cluster.local:8065",
  "env": {
    "mm_email": "test@bigbang.dev",
    "mm_user": "bigbang",
    "mm_password": "Bigbang#123"
  }
}
```

Any cypress tests should be written following cypress best practices and functionally test the UI components of a package.

Your final directory structure and files should look like this:
```
|-- chart
|  |-- Chart.yaml (which includes the library dependency)
|  |-- tests
|  |  `-- cypress
|  |    |-- cypress.json
|  |    `-- *.spec.js
|  `-- templates
|     `-- tests
|        `-- test.yaml (which uses the library templates)
`-- tests
   `-- test-values.yaml (with your bbtests values)
```

#### Scripts

To include the Helm test templates for script based tests you will need to make a file under `chart/templates/tests` which includes the content below:

```yaml
{{- include "bb-test-lib.script-configmap.base" . }}
---
{{- include "bb-test-lib.script-runner.base" . }}
```

This will work for a "base" install, but if you want to override anything (example below shows how to add labels), you can include different templates and create package specific templates with the overrides:
```yaml
{{- include "bb-test-lib.script-configmap.overrides" (list . "mattermost-test.script-configmap") }}
{{- define "mattermost-test.script-configmap" }}
metadata:
  labels:
    {{ include "mattermost.labels" . | nindent 4 }}
{{- end }}
---
{{- include "bb-test-lib.script-runner.overrides" (list . "mattermost-test.script-runner") -}}
{{- define "mattermost-test.script-runner" -}}
metadata:
  labels:
    {{ include "mattermost.labels" . | nindent 4 }}
{{- end }}
```

The second step to implementing these tests will be including values in your `test-values.yaml` file that would be needed for the tests. There are 3 main values you will want to consider, only the image value is required:
- `bbtests.scripts.image`: REQUIRED, this is the image name that should be used to run your script. This should be a small image with the CLI tools needed (for example, to test Minio you would want an image with Minio CLI). Ironbank images are not required but are preferred if one exists with the CLI tool you need installed. This field supports Helm templating if you want to grab an image being used elsewhere in your values (ex: `image: "{{ .Values.my.spec.to.image }}").
- `bbtests.scripts.secretEnvs`: This is where you should put any configuration that your tests need from secrets that are created by the helm chart (common examples are passwords) - Helm templating is supported here with proper syntax (braces must be wrapped in quotes, any quotes inside braces must be escaped)
- `bbtests.scripts.envs`: This is where any configuration that is not in pre-existing secrets should go (common examples are the service name to hit and standard usernames) - Helm templating is also supported here with the same restrictions of syntax.

A sample is included below:
```yaml
bbtests:
  scripts:
    image: "{{ .Values.mcImage }}"
    envs:
      MINIO_PORT: "{{ .Values.service.port }}"
      MINIO_HOST: "{{ include \"minio.serviceName\" . }}"
    secretEnvs:
      - name: SECRET_KEY
        valueFrom:
          secretKeyRef:
            name: "{{ .Values.minioRootCreds }}"
            key: secretkey
      - name: ACCESS_KEY
        valueFrom:
          secretKeyRef:
            name: "{{ .Values.minioRootCreds }}"
            key: accesskey
```

Finally, any script files (the helm template will run any and all files in the scripts folder) must be placed in the directory `chart/tests/scripts/`. Your test script(s) should run the CLI tool(s) and perform any other necessary operations to functionally test the package. Make sure to call out the proper shell / executable to run your script (for example call out that bash should be used with `#!/bin/bash` as the first script line). If you need any additional files for running the scripts they should be placed under subfolders so that the pipeline does not try to run them as scripts. Scripts can be expected to run in sequential order based on file name (files beginning with 0-9, then A-Z, then a-z).

An example is provided below for Minio:
```bash
#!/bin/bash
set -ex
mc config host add bigbang http://${MINIO_HOST}:${MINIO_PORT} ${ACCESS_KEY} ${SECRET_KEY}
# cleanup from previous runs
mc rb bigbang/foobar --force || true
mc mb bigbang/foobar
mc ls bigbang/foobar
base64 /dev/urandom | head -c 10000000 > /tmp/file.txt
md5sum /tmp/file.txt > /tmp/filesig
mc cp /tmp/file.txt bigbang/foobar/file.txt
mc ls bigbang/foobar/file.txt
mc cp bigbang/foobar/file.txt /tmp/file.txt
mc rb bigbang/foobar --force
md5sum -c /tmp/filesig
```

Your final directory structure and files should look like this:
```
|-- chart
|  |-- Chart.yaml (which includes the library dependency)
|  |-- tests
|  |  `-- scripts
|  |    `-- mytest.sh
|  `-- templates
|     `-- tests
|        `-- test.yaml (which uses the library templates)
`-- tests
   `-- test-values.yaml (with your bbtests values)
```

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

All variables are optional, but can provide additional flexibility for more complicated packages.

Make sure to also update the ref to the tagged version of the pipeline you want to use. Latest versions and changes can always be found in the [CHANGELOG](./CHANGELOG.md).

```yaml
include:
  - project: 'platform-one/big-bang/pipeline-templates/pipeline-templates'
    ref: '1.1.0'
    file: '/templates/package-tests.yml'
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
- `namespace`: Optional, pass in a namespace to install the dependency under (useful if the dependency needs to be installed under a specific namespace, i.e. gitlab-runners need to be in gitlab namespace), defaults to the dependency name (top level yaml) if not provided
- `package-name`: Optional, pass in a specific name for the dependency to be installed as via Helm. Can be helpful to match the HelmRelease names at the top Big Bang level. Defaults to the dependency name (top level yaml) if not provided.

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
