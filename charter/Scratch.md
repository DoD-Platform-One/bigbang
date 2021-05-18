# Scratch

Comments from meetings

## Apps

* Should any product need to be licence (e.g. why Anchore Enterprise and not Anchore)
* Should everything used by apps be internal?  E.g. Postgres required for Keycloak
* Which of Anchore vs Anchore Enterprise

* Consistent Interface.  Only "supported" BigBang configuration

Testing stuff

## Kubernetes Tools E2E Testing Frameworks

### Each Applications E2E tests

Is there a way to get each application to run its own e2e tests against the deployed version?

e.g. for Argo:
<https://github.com/argoproj/argo-cd/blob/master/.github/workflows/ci-build.yaml>

### Istio

Istio uses Prow: <https://github.com/istio/test-infra>

### KUTTL

KUTTL allows for the verification of Kubernetes objects (and status) based on application of various kubernetes yaml objects.
This easily allows for testing the health of all the objects (per status fields), but doesn't provide integration tests unless we
build all the integration tests into CRDs or into Kubernetes Jobs:

APP

* manifests/linting
* k3d healthy"
* smoke tests

Integration Tests
*

Single release of all app versions in single place.  Tested by BB

Customer extensions need to be tested in their own moc environment

Common Integration:

* "App of Apps"

Mock Integration environments

* sample implementation of customer

## Keycloak

Table discussion

API:*

* can't change image tags
* can change repo to allow for airgapped repos
