# Kyverno Policy Unit Tests

This document will guide developers on creating unit tests for Kyverno Policies.

## Overview

The following resources in `chart/templates/tests` are setup to support testing Kyverno policies:

- Service Account: Account used for pod running the tests
- Cluster Role: RBAC permissions to create, delete, and view Kyverno and test resources
- Cluster Role Binding: Attaches cluster role to service account
- Config Map: Manifests (.yaml) to use for testing policies.  These are located in `chart/tests/manifests`
- GluOn: Big Bang library to create a Config Map holding the script and a Pod for running the script.  The script is located in `chart/tests/scripts`

In addition, `bbtest` values from `tests/test-values.yaml` are used to configure the test pod.

When a helm test is started, the pod `kyverno-policies-script-test` will run with the following attributes:

- Runs a `kubectl` container using an Iron Bank image
- [Test manifests](#test-manifests) (in ConfigMap) are mounted to `/yaml`
- Test scripts (in ConfigMap) are mounted to `/src`
- Contains an environmental variable named `ENABLED_POLICIES` that holds a list of policies that should be tested
- Runs using service account for additional privileges

## Local Testing

1. Deploy Kyverno using the Kyverno Helm chart
1. Deploy Kyverno Policies using the Helm chart and test values:

    ```shell
    helm upgrade -i -n kyverno --create-namespace -f tests/test-values.yaml kyverno-policies chart
    ```

1. Run Helm tests

    ```shell
    helm test -n kyverno kyverno-policies
    ```

## Test Values

All validation policies should be set to "audit" for the failure action.  This allows Kyverno to capture multiple violations in a policy report.  Setting policies to "enforce" will cause Kyverno to stop after the first resource violation.

Policies should have values setup to allow for both enforcement and non-enforcement of the policy.  Enforcement means the policy blocks, generates, or mutates a resource.  Non-enforcement means the policy allows or ignores a resource (e.g exception).

## Tests

The following tests are run in the test script:

1. **Enabled cluster policies are deployed and ready**
    Verifies that all the cluster policies from `ENABLED_POLICIES` successfully deployed and are in the "Ready" state.  A failure indicates a syntax problem with the policy.
1. **Disabled cluster policies are not deployed**
    Verifies no unexpected policies were deployed.  A failure means the `.enabled` flag was not implemented properly in the policy.
1. **All enabled policies have a test**
    Verifies every policy has at least one test case for enforcement (e.g. blocked, generated, mutated) and one test case for non-enforcement (e.g. allowed, excluded).
1. **Validation policies allow or block manifests properly**
    Verifies that [test manifests](#test-manifests) are either allowed or blocked by a validate policy.
1. **Generate policies create resources when appropriate**
    Verifies that [test manifests](#test-manifests) trigger or don't trigger the generation of a resource by a generate policy.
1. **Mutate policies modify manifests when appropriate**
    Verifies that [test manifests](#test-manifests) are mutated or left alone by a mutate policy.

## Test Manifests

Test manifests are located in `chart/tests/manifests/*.yaml`.  They are designed to deploy resources that tests enforcement or nonenforcement of a single policy.  Each manifest should be named the same as the policy it is enforcing.  Manifests can contain multiple resources.

Inside the manifest, each test case should have a comment describing what is being tested.  For example `Test 1: Containers adding non-approved capabilities should not be allowed`.

Annotations are required for the script to know how to test each policy:

- `kyverno-policies-bbtest/type`: Indicates the type of test that should be applied to the manifest.  This can be either `validate`, `generate`, or `mutate`.

### Validate Policies

- `kyverno-policies-bbtest/expected`: The expected action that Kyverno will take with the manifest.  Use `pass` for allow or `fail` for block.

### Generate Policies

- `kyverno-policies-bbtest/expected`: The expected action that Kyverno will take with the manifest.  Use `generate` to indicate a resource should be generated or `ignore` for no action.
- `kyverno-policies-bbtest/kind`: The kind of the generated resource to check
- `kyverno-policies-bbtest/name`: The name of the generated resource to check
- `kyverno-policies-bbtest/namespace`: If the generation is in a different namespace than the annotated resource, the namespace to find the generated resource.

> If `expected` is set to `ignore`, `kind`, `name` and `namespace` will still be used to validate that the resource was **NOT** generated.

### Mutate Policies

- `kyverno-policies-bbtest/expected`: The expected action that Kyverno will take with the manifest.  Use `mutate` to indicate the manifest should be mutated or `ignore` for no action.
- `kyverno-policies-bbtest/key`: The JMES path to the key that should be mutated.  The syntax should work with kubectl's `--jsonpath` option
- `kyverno-policies-bbtest/value`: The expected value of the key after mutation.
- `kyverno-policies-bbtest/kind`: If the mutation is not on the annotated resource, the kind of the mutated resource to check
- `kyverno-policies-bbtest/name`: If the mutation is not on the annotated resource, the name of the mutated resource to check
- `kyverno-policies-bbtest/namespace`: If the mutation is not on the annotated resource and the mutated resource is in a different namespace than the annotated resource, the namespace to find the mutated resource.

> If `expected` is set to `ignore`, `key` and `value` will still be used to validate the result.  The test will check that `key` does **NOT** exist or that the key's value does **NOT** match `value`.  Leaving `key` blank will result in a failure.
