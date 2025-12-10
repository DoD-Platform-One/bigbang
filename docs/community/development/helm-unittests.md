# Helm Unit Testing

[[_TOC_]]

## Overview

Helm unit tests provide a way to test Helm chart templates without deploying to a Kubernetes cluster. Big Bang uses the [helm-unittest plugin](https://github.com/helm-unittest/helm-unittest) to validate that Helm templates render correctly under various conditions and configurations.

Unlike [Helm Chart Tests](https://helm.sh/docs/topics/chart_tests) (which deploy pods to a live cluster and test runtime behavior), helm unit tests validate template rendering logic, schema validation, and expected output structure before any actual deployment occurs.

## Prerequisites

### Install Helm Unittest Plugin

The helm unittest plugin must be installed to run tests:

```bash
helm plugin install https://github.com/helm-unittest/helm-unittest
```

**Note on Test Directory Location**: The Helm unittest plugin conventionally looks for tests in `chart/tests/`, but Big Bang places unit tests in `chart/unittests/` to avoid confusion with existing end-to-end (e2e) Helm Chart Tests that run in live Kubernetes clusters. This separation keeps unit tests (which validate template rendering) distinct from runtime integration tests.

## Running Tests

### Run All Tests

To run all unit tests in the Big Bang chart:

```bash
helm unittest chart -f "unittests/**/*_test.yaml"
```

### Run Specific Test Suites

You can run specific test files or directories:

```bash
# Run schema validation tests only
helm unittest chart -f "unittests/schema/*_test.yaml"

# Run a specific test file
helm unittest chart -f "unittests/schema/umbrella_test.yaml"

# Run template helper tests
helm unittest chart -f "unittests/template:*_test.yaml"
```

### Debugging Tests

To enable verbose output and view the rendered YAML templates during test execution, use the `-d` flag:

```bash
helm unittest chart -f "unittests/**/*_test.yaml" -d
```

When the `-d` (or `--debugPlugin`) flag is enabled, helm unittest creates a `.debug/` directory containing the rendered YAML output for each template processed during the tests. This is useful for:

- Inspecting the actual rendered templates to understand test failures
- Verifying that your Helm values produce the expected template output
- Debugging complex template logic and conditionals

## Test Organization

Big Bang organizes helm unit tests into several categories:

### Schema Validation Tests

Located in [chart/unittests/schema/](../../../chart/unittests/schema/), these tests validate that the Helm chart's values conform to the expected schema.

#### Example: Valid Configuration

```yaml
suite: Schema Validation - Git Configuration
tests:
  - it: should pass validation with git credentials
    set:
      git:
        credentials:
          username: "myuser"
          password: "mypassword"
    asserts:
      - notFailedTemplate: {}
```

#### Example: Invalid Configuration

```yaml
suite: Schema Validation - Git Configuration
tests:
  - it: should fail validation with username but no password
    set:
      git:
        credentials:
          username: "myuser"
          password: null
    asserts:
      - failedTemplate:
          errorPattern: ".*password.*"
```

### Template Helper Tests

Located in [chart/unittests/](../../../chart/unittests/), these tests validate custom Helm template functions defined in `_helpers.tpl`.

Template helper tests ensure that custom template functions produce correct output across various input scenarios. For detailed information on Big Bang's template self-testing framework and how to write tests for custom template helpers, see the [Template Self-testing Guide](self-testing.md).

### Package-Specific Tests

Located in [chart/unittests/packages/](../../../chart/unittests/packages/), these tests validate that package-specific templates render correctly for individual packages.

## Additional Resources

- [Helm Unittest Plugin Documentation](https://github.com/helm-unittest/helm-unittest/blob/main/DOCUMENT.md)
- [Big Bang Template Self-testing Guide](self-testing.md)
