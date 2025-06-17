# BigBang Schema Utilities

This directory contains utilities and tests for managing and validating the BigBang Helm chart values schema.

## Dependencies
- [Bats](https://github.com/bats-core/bats-core) and [bats-assert](https://github.com/bats-core/bats-assert) for testing (installed via `npm install`).
- `jq`, `sponge`, and `curl` for schema refresh operations.


## Run Schema Tests

- **test**: Installs dependencies (if needed) and runs the Bats test suite to validate Helm chart values against the schema using test cases in `test-values/`.
  ```sh
  make install
  make test
  ```

## Adding Schema Tests

- Test cases are organized under `test-values/<feature>/{valid,invalid}/`.
- Each file in a `valid` directory should pass schema validation; each file in an `invalid` directory should fail.
- The Bats test suite (`schema.bats`) will automatically run all these cases using `helm template`.

To add a new test case, place your YAML file in the appropriate `valid` or `invalid` directory under the relevant feature.


## Updating schema for known objects via CRDs (schema-refresh.sh)

This script updates the `values.schema.json` file by fetching the latest schema definitions from the Flux HelmRelease CRDs in a running Kubernetes cluster.

**NOTE:** The refresh operation is designed to be an aid, but subtle differences between the usage of the CRDs and our values schema will necessitate manual intervention.

**Requirements:**
- You must have `kubectl` access to a running cluster with the Flux CRDs installed.
- The script starts a local `kubectl proxy` on port 8080 to access the Kubernetes OpenAPI.
- It fetches and updates the relevant schema sections in `../chart/values.schema.json` using `jq` and `sponge`.

**Usage:**
```sh
make refresh
```