# BB Test Templates

Currently two testing types are supported through the
library, scripts (for CLI testing - think bash, python, etc) and cypress (for UI testing). These two test types are
described below along with examples of how to implement them. NOTE: If your package can be interacted via a UI and a CLI
both test types should be included. By default UI tests run before CLI tests the way the library is written, but this
can be overridden as described below.

Tests will automatically be run by the pipelines, but if you wish to run them locally you will need to install the
package with the test values, then run `helm test {{HELMRELEASE_NAME}} -n {{HELMRELEASE_NAMESPACE}}` replacing the
variables with the proper values for your package (you can check the helmrelease name and namespace with `helm ls -A`).

You will need to include the `bbtests.enabled` toggle set to true in your test-values so that the tests are deployed.

```yaml
bbtests:
  enabled: true
```

## Cypress

To include the Helm test templates for Cypress you will need to make a file under `chart/templates/tests` which includes
the content below:

```yaml
{{- include "gluon.tests.cypress-configmap.base" .}}
---
{{- include "gluon.tests.cypress-runner.base" .}}
```

This will work for a "base" install, but if you want to override anything (example below shows how to add labels), you
can include different templates and create package specific templates with the overrides:

```yaml
{{- include "gluon.tests.cypress-configmap.overrides" (list . "mattermost-test.cypress-configmap") }}
{{- define "mattermost-test.cypress-configmap" }}
metadata:
  labels:
    {{ include "mattermost.labels" . | nindent 4 }}
{{- end }}
---
{{- include "gluon.tests.cypress-runner.overrides" (list . "mattermost-test.cypress-runner") -}}
{{- define "mattermost-test.cypress-runner" -}}
metadata:
  labels:
    {{ include "mattermost.labels" . | nindent 4 }}
{{- end }}
```

The second step to implementing these tests will be including values in your `test-values.yaml` file that would be
needed for the tests. There are several values you will want to consider, all values are optional:

- `bbtests.cypress.artifacts`: This should be set to true in almost all cases so that artifacts are exported from the
helm test pods and available as artifacts in the pipeline.
- `bbtests.cypress.exports`: This should be set to true if you want to export values from your Cypress tests to be used in your script tests. Files should be written to the subdirectory `exports` and will then be available at that same subdirectory from the script run location in the script runner.
- `bbtests.cypress.secretEnvs`: This is where you should put any configuration that your tests need from secrets that
  are created by the helm chart (common examples are passwords) - Helm templating is supported here with proper syntax
  (braces must be wrapped in quotes, any quotes inside braces must be escaped)
- `bbtests.cypress.envs`: This is where any configuration that is not in pre-existing secrets should go (common examples
  are the service name to hit and usernames) - Helm templating is also supported here with the same restrictions of
  syntax. While you may be able to place ENVs into your `cypress.json`, that will not support Helm templating, which is
  the major benefit of using values for ENVs.
- `bbtests.cypress.additionalVolumes`: This defines additional volumes for the cypress testing pod that is not
  one of the pre-existing testing volumes. This takes normal Kubernetes `volume` configurations as yamls. This supports
  helm templating for these values.
- `bbtest.cypress.additionalVolumeMounts`: This defines additional volumes to mount into the main cypress container itself.
  This takes normal Kubernetes `volumeMount` configuration in `yaml`. This supports `Helm` templating for values.
- `bbtest.cypress.resources`: This defines requests and limits to set in the main cypress container itself. This takes normal Kubernetes `resources` configuration in `yaml`. This supports `Helm` templating for values.
- `bbtests.istio.hosts`: This defines istio hostnames to add to the cypress test pods /etc/hosts for resolution.
  It should be defined as a list and supports helm templating. Note this will also apply to any script tests.

A sample is included below:

```yaml
bbtests:
  enabled: true
  cypress:
    artifacts: true
    exports: true
    additionalVolumeMounts:
      - name: "{{ .Chart.Name }}-example"
        mountPath: /example
      - name: "{{ .Chart.Name }}-example-config"
        mountPath: /otherexample
        subpath: something
    additionalVolumes:
      - name: "{{ .Chart.Name }}-example"
        emptyDir: {}
      - name: "{{ .Chart.Name }}-example-config"
        configMap:
          name: "{{ .Chart.Name }}-example-config"
    envs:
      HOST: "{{ .Values.service.port }}"
      MINIO_HOST: '{{ include "minio.serviceName" . }}'
      cypress_url: 'http://{{ include "minio.serviceName" . }}:{{ .Values.service.port }}'
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
    resources:
      requests:
        cpu: "1"
        memory: "1Gi"
      limits:
        cpu: "1"
        memory: "1Gi"
  istio:
    hosts:
      - "minio.{{ .Values.hostname }}"
```

NOTE: ENVs must be prefixed with `cypress_` to be available to Cypress.

Finally, a `cypress.json` file and all `*.spec.js` tests must be placed at the same directory level
`chart/tests/cypress/`. Your `cypress.json` should follow the traditional cypress format, an example is included below:

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

### Cypress exports

Cypress "exports" should be enabled if you want to pass information from your Cypress test to your script test. [Cypress documentation](https://docs.cypress.io/api/commands/writefile) covers many scenarios for how to use the `writeFile` function to create plaintext, JSON, and other file types for different needs. To make sure that files are properly passed, they need to be written to the `exports` subdirectory. See the below example as a way of writing the value of an input field to a file for availability in your script. One important option to know about is the append option as shown below:

```js
cy.writeFile('exports/envs-from-cypress.env', 'export MY_TOKEN=', { flag: 'a+' })
cy.get('input[id="token"]').invoke('val').then(token => cy.writeFile('exports/envs-from-cypress.env', token + '\n', { flag: 'a+' }))
```

These files will be available in any scripts you run at the same file structure (under the subdirectory exports). Note that nothing is done with the files, so it is up to your script on how you would like to extract and use the files. The example above shows writing out an `export` "command" so that the file can be easily sourced, but you could write out a yaml or json file to parse instead (or any other thing you want to do with the file).

### Cypress artifacts

Cypress artifacts are written to the host running the k3d cluster at /cypress. This is done via hostPath mounts from the runner -> k3d host -> helm test pod. When gatekeeper is running, exceptions will need to be added to its configuration to allow this. See "Add gatekeeper exceptions" in this document.

## Scripts

To include the Helm test templates for script based tests you will need to make a file under `chart/templates/tests`
which includes the content below:

```yaml
{{- include "gluon.tests.script-configmap.base" .}}
---
{{- include "gluon.tests.script-runner.base" .}}
```

This will work for a "base" install, but if you want to override anything (example below shows how to add labels), you
can include different templates and create package specific templates with the overrides:

```yaml
{{- include "gluon.tests.script-configmap.overrides" (list . "mattermost-test.script-configmap") }}
{{- define "mattermost-test.script-configmap" }}
metadata:
  labels:
    {{ include "mattermost.labels" . | nindent 4 }}
{{- end }}
---
{{- include "gluon.tests.script-runner.overrides" (list . "mattermost-test.script-runner") -}}
{{- define "mattermost-test.script-runner" -}}
metadata:
  labels:
    {{ include "mattermost.labels" . | nindent 4 }}
{{- end }}
```

The second step to implementing these tests will be including values in your `test-values.yaml` file that would be
needed for the tests. There are several values you will want to consider, only the image value is required:

- `bbtests.scripts.image`: REQUIRED, this is the image name that should be used to run your script. This should be a
  small image with the CLI tools needed (for example, to test Minio you would want an image with Minio CLI). Ironbank
  images are not required but are preferred if one exists with the CLI tool you need installed. This field supports Helm
  templating if you want to grab an image being used elsewhere in your values (ex: `image: "{{ .Values.my.spec.to.image }}"`).
- `bbtests.scripts.secretEnvs`: This is where you should put any configuration that your tests need from secrets that
  are created by the helm chart (common examples are passwords) - Helm templating is supported here with proper syntax
  (braces must be wrapped in quotes, any quotes inside braces must be escaped)
- `bbtests.scripts.envs`: This is where any configuration that is not in pre-existing secrets should go (common examples
  are the service name to hit and standard usernames) - Helm templating is also supported here with the same
  restrictions of syntax.
- `bbtests.scripts.additionalVolumes`: This defines additional volumes for the cypress testing pod that is not
  one of the pre-existing testing volumes. This takes normal Kubernetes `volume` configurations as yamls. This supports
  helm templating for these values.
- `bbtest.scripts.additionalVolumeMounts`: This defines additional volumes to mount into the main cypress container itself.
  This takes normal Kubernetes `volumeMount` configuration in `yaml`. This supports `Helm` templating for values.
- `bbtest.scripts.resources`: This defines requests and limits to set in the main script container itself. This takes normal Kubernetes `resources` configuration in `yaml`. This supports `Helm` templating for values.
- `bbtests.istio.hosts`: This defines istio hostnames to add to the script test pods /etc/hosts for resolution.
  It should be defined as a list and supports helm templating. Note this will also apply to any cypress tests.

A sample is included below:

```yaml
bbtests:
  enabled: true
  scripts:
    image: "{{ .Values.mcImage }}"
    additionalVolumeMounts:
      - name: "{{ .Chart.Name }}-example"
        mountPath: /example
      - name: "{{ .Chart.Name }}-example-config"
        mountPath: /otherexample
        subpath: something
    additionalVolumes:
      - name: "{{ .Chart.Name }}-example"
        emptyDir: {}
      - name: "{{ .Chart.Name }}-example-config"
        configMap:
          name: "{{ .Chart.Name }}-example-config"
    envs:
      MINIO_PORT: "{{ .Values.service.port }}"
      MINIO_HOST: '{{ include "minio.serviceName" . }}'
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
    resources:
      requests:
        cpu: "1"
        memory: "1Gi"
      limits:
        cpu: "1"
        memory: "1Gi"
  istio:
    hosts:
      - "minio.{{ .Values.hostname }}"
```

Finally, any script files (the helm template will run any and all files in the scripts folder) must be placed in the
directory `chart/tests/scripts/`. Your test script(s) should run the CLI tool(s) and perform any other necessary
operations to functionally test the package. Make sure to call out the proper shell / executable to run your script
(for example call out that bash should be used with `#!/bin/bash` as the first script line). If you need any additional
files for running the scripts they should be placed under subfolders so that the pipeline does not try to run them as
scripts. Scripts can be expected to run in sequential order based on file name (files beginning with 0-9, then A-Z,
then a-z).

As a reminder, if you had any cypress "exports" those will be accessible via the exports directory for usage in your script (provided you toggled `bbtests.cypress.exports` on).

An example is provided below for Minio:

```bash
#!/bin/bash
set -ex
source exports/envs-from-cypress.env
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

#  Add Gatekeeper exceptions

Most bigbang clusters will have gatekeeper enabled. When running in a bigbang integration test, these exceptions are required so that the artifacts generated by cypress tests (screenshots and videos) can be exported after the test is complete.

Ensure this is in place in your bigbang test-values.yaml in the gatekeeper section under gatekeeper.values.violations:

```yaml
      volumeTypes:
        parameters:
          excludedResources:
          # Add all cypress test pods here to allow hostpath cypress mount
          - namespace/pod-name
      allowedHostFilesystem:
        parameters:
          excludedResources:
          # Add all cypress test pods here to allow hostpath cypress mount
          - namespace/pod-name
```