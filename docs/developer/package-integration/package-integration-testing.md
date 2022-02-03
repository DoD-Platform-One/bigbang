# Big Bang Package: Testing

Usually, Helm charts come with a set of Helm tests that can be run to test the deployment of the application.  Big Bang requires some additional tests to verify integration is working as expected.  By adding additional tests, the goal is to verify that the package is functioning.  For example, we may want to validate that

- The HTTPS endpoint can be reached
- The admin user can login using the configured (or randomized) password
- A non-admin user can be created and can login
- Data can be stored and retrieved from the database
- Artifacts can be stored and retrieved from the object storage
- Interactions with other services/packages works

## Prerequisites

- Package helm chart with CI settings pointing to one of bigbang's [package pipelines](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/ci-integration-doc/docs/developer/package-integration/package-integration-pipeline.md)

## Integration

Bigbang provides a library helm chart called [Gluon](https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon) to help simplify the process of creating both cypress and script helm tests.

To use this library the following needs to be added to either your `chart/Chart.yaml` or `chart/requirements.yaml` (NOTE: the latest version can be found [here](https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/tags)):
```yaml
dependencies:
- name: gluon
  version: "0.2.5"
  repository: "oci://registry.dso.mil/platform-one/big-bang/apps/library-charts/gluon"
```
Once this is saved the following commands need to be run on your helm chart to add the dependency:
```
export HELM_EXPERIMENTAL_OCI=1
helm dependency update chart
```
(NOTE: helm cli version 3.7.0 or above is needed)

Then in your chart/values.yaml add values for bbtests, any variables used, and default it to false:
```yaml
# Bigbang helm test values default disabled
bbtests:
  enabled: false
  cypress:
    artifacts: true
    envs:
      cypress_url: 'http://{{ template "podinfo.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local:{{ .Values.service.externalPort }}'
  scripts:
    envs:
      URL: 'http://{{ template "podinfo.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local:{{ .Values.service.externalPort }}'
```
(NOTE: At the package level we are pointing to the service and service port instead of the istio virtual service because istio isn't enabled by default. At the bigbang test level we will point to the virtualservice url because istio will be present.)

We will enable these tests in `tests/test-values.yaml`:
```yaml
bbtests:
  enabled: true
```
### Cypress test
Now we need to add the cypress gluon template yaml to `chart/templates/tests/cypress-test.yaml`:
```yaml
{{- include "gluon.tests.cypress-configmap.base" .}}
---
{{- include "gluon.tests.cypress-runner.base" .}}
```

We need to add a cypress test to `chart/tests/cypress/podinfo-health.spec.js`:

```yaml
describe('Basic Podinfo', function() {
  it('Check Podinfo is accessible', function() {
      cy.visit(Cypress.env('url'))
  })
})
```
(NOTE: This is basic cypress test that will visit the `cypress_url` defined in values.yaml. For more information on cypress tests visit [here](https://docs.cypress.io/guides/overview/why-cypress#In-a-nutshell))

We also need a cypress.json config file with any cypress configurations we need placed `chart/tests/cypress/cypress.json`:

```json
{
    "pluginsFile": false,
    "supportFile": false,
    "fixturesFolder": false
}  
```
### Script test
Now we need to add the script gluon template yaml to `chart/templates/tests/script-test.yaml`:
```yaml
{{- include "gluon.tests.script-configmap.base" .}}
---
{{- include "gluon.tests.script-runner.base" .}}
```

We need a script to run `chart/tests/scripts/script-test.sh`:
```bash
#!/bin/bash
set -ex

echo "-----------------------------------------"
echo "BEGIN podinfo jwt test"
echo "-----------------------------------------"
TOKEN=$(curl -sd 'test' ${URL}/token | jq -r .token) &&
curl -sH "Authorization: Bearer ${TOKEN}" ${URL}/token/validate | grep test
echo "-----------------------------------------"
echo "END podinfo jwt test"
echo "-----------------------------------------"
```

More information on cypress tests and creating tests with scripts for testing non-UI portions of an app can be found [here](https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/blob/master/docs/bb-tests.md)

## Validation

To validate these changes and view the cypress test we can create a merge request with these changes and a pipeline will automatically kick off deploying our package and running the helm tests. Artifacts of these tests (screenshots and videos) are stored in the `Clean Install`, `Upgrade`, and `Integration Test` Jobs. Just click one of the jobs and there will be `job artifacts` on the right pane.
