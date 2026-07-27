# Test values

The umbrella pipeline uses `test-values.yaml` as its complete test configuration. Variant files are overlays unless they explicitly state otherwise.

The values precedence for variant jobs is:

1. `test-values.yaml`
2. `chart/ingress-certs.yaml`
3. The selected variant overlay

Later values override earlier values. Variant overlays should therefore contain only settings that differ from `test-values.yaml`. Do not copy the full base configuration into an overlay: duplicate empty or stale values can unintentionally replace values added to the base by the pipeline.

The pipeline implementation is the source of truth for this precedence:

- [`generate_dynamic_tests.py`](https://repo1.dso.mil/big-bang/pipeline-templates/pipeline-templates/-/blob/master/bbpops-cli/misc/generate_dynamic_tests.py#L310-320) assigns `test-values.yaml` as `CI_VALUES_FILE` and the selected variant as `CI_VALUES_OVERRIDES_FILE`.
- [`deploy_bigbang.py`](https://repo1.dso.mil/big-bang/pipeline-templates/pipeline-templates/-/blob/master/bbpops-cli/deployment/deploy_bigbang.py#L333-400) merges certificate values into the base and then passes the variant override to Helm.

If pipeline behavior changes, update this document and its overlay regression tests to match the implementation.

Current test values files include:

- `test-values.yaml`: base configuration for umbrella CI deployments.
- `test-values-ambient.yaml`: enables Istio ambient mode on top of the base configuration.
- `oci-values.yaml`: OCI-specific overlay.
- `extended/*.yaml`: focused overlays for extended test scenarios.
- `eks-test-values.yaml` and `rke2-test-values.yaml`: environment-specific overlays applied by their respective jobs.

For a local ambient render or install, apply the files in the same order:

```shell
helm template bigbang chart \
  -f tests/test-values.yaml \
  -f chart/ingress-certs.yaml \
  -f tests/test-values-ambient.yaml
```
