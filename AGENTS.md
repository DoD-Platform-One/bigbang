# AGENTS.md

<!-- big-bang-agents-standard: 1 -->

## Repository Purpose

This repository owns the Big Bang umbrella Helm chart, its bootstrap manifests, integrated-package orchestration, configuration schema, migration utilities, and central documentation. The chart renders Flux sources and reconciliation resources; it does not contain the independently versioned package charts it deploys.

Make umbrella-wide configuration, package wiring, dependency, generation, and documentation changes here. Make workload templates, package defaults, and package-specific tests in the corresponding package repository. General product behavior remains owned by the upstream project.

## Sources of Truth

- `chart/package-metadata.yaml`, `chart/values.yaml`, and `chart/values.schema.json` define built-in packages, source pins, defaults, and the public values contract.
- `chart/templates/` defines rendered behavior; `_helpers.tpl` contains shared package, values, dependency, ambient, and network-policy contracts.
- `base/` defines the Kustomize and Flux bootstrap path.
- `chart/unittests/` and `tests/bats/` define chart, generator, migration, script, and overlay behavior.
- [Repository agent instructions](docs/community/development/agent-instructions.md), [Contributing](CONTRIBUTING.md), and the [documentation guide](docs/README.md) define repository and documentation practices.
- [ADR 5](docs/community/adrs/0005-passthrough-chart.md), [ADR 10](docs/community/adrs/0010-upstream-values-readme-documentation.md), and [ADR 11](docs/community/adrs/0011-unified-package-configuration-and-metadata.md) define upstream and package-configuration boundaries.
- `CODEOWNERS` defines review ownership for repository paths.
- `.markdown-link-check.json` and `.markdown-link-check.yaml` configure the CI documentation link checker.
- CI uses `pipelines/bigbang.yaml@big-bang/pipeline-templates/pipeline-templates:master` through the GitLab project setting; the [CI workflow](docs/community/development/ci-workflow.md) explains the external pipeline.

## Repository Layout

- `chart/`: umbrella chart, values contract, generated package metadata, Helm templates, and unit tests.
- `base/`: GitOps bootstrap resources and pinned Flux installation manifests.
- `docs/`: published user, operator, package-integration, and contributor docs.
- `scripts/`: generators, migration tools, rendering tools, and cluster operations.
- `tests/`: shared deployment values and Bats suites.
- `blog/`: release and feature articles, including historical material.

## Working Rules

- A `chart/templates/<package>/` family includes its source, credentials, values, namespace, Secrets, HelmRelease, migrations, post-renderers, and tests. Package values or `bb-common` normally own workload behavior rather than copied workload templates here.
- `bigbang.normalizePackageAliases` preserves legacy and `packageConfiguration.version: v1` behavior. Under v1, canonical built-in values override legacy values; unknown names remain custom packages.
- Preserve values precedence: `common`, then generated `defaults`, then user `overlays`. Sprig merge operations mutate their first argument, so deep-copy values before using `set`, `unset`, `merge`, or `mergeOverwrite`.
- Flux names, namespaces, source references, values Secret names, HelmRelease names, and `dependsOn` entries are compatibility interfaces. `offline: true` suppresses package GitRepository creation only.
- Ambient mode is effective when global ambient mode or ztunnel enables it; Istio CNI, ztunnel, Gateway API, policy, HBONE, and dependency behavior are coupled.
- `_bb-common-migrations.tpl` and deprecated aliases remain compatibility code until their documented major-version removal boundary.

## Commands

Run these local, read-only checks from the repository root. They do not contact a cluster or intentionally change tracked files.

- `scripts/generate-package-schemas.sh --check` requires `jq` and Mike Farah `yq` v4. It validates `chart/package-metadata.yaml` and compares temporary output with `chart/values.schema.json` and the generated metadata block in `scripts/migrate-values-3-to-4.sh`. If stale, run the reported `--write` command and review both files.
- `scripts/generate-values-reference.sh --check` requires `helm-docs` v1.14.2, or `HELM_DOCS_BIN` pointing to that version. It renders into a temporary directory and compares the result with `docs/configuration/base-config.md`. If stale, run the reported `--write` command and review that generated file.
- `helm lint ./chart` requires Helm and validates the umbrella chart and its vendored dependencies without rendering every test scenario.
- `helm unittest chart -f 'unittests/**/*_test.yaml'` requires Helm plus the `helm-unittest` plugin. It renders and tests the full chart unit-test suite without deploying resources; add `-d` only when needed because debug mode creates `.debug/` output.
- `bats --jobs 4 --recursive tests/bats/` requires Bats with parallel-runner support and runs the complete shell, migration, generator, and overlay suite. Use the matching focused Bats file while iterating.
- `kubectl kustomize ./base >/dev/null` and `kubectl kustomize ./base/flux >/dev/null` require `kubectl` and verify that both bootstrap overlays render locally. Despite using `kubectl`, these commands do not access the active kubeconfig or apply resources.

## Validation

| Change area | Required focused checks | Additional validation |
| --- | --- | --- |
| Agent or documentation guidance | External `agent instructions` and `link check` jobs | Verify local paths, commands, and links. |
| Package metadata, schema, values, or migrations | Relevant generator check and focused Bats | Review generated diffs and render legacy plus v1 values when applicable. |
| Templates, helpers, names, or dependencies | Focused and full Helm unit tests | Render changed enabled, disabled, source, and offline cases. |
| Ambient, Istio, or policy behavior | Relevant Helm tests and `tests/bats/values-overlays/values-overlays.bats` | Render ordinary and ambient overlays; use external integration CI for cross-package behavior. |
| Scripts or bootstrap resources | Focused Bats or `kubectl kustomize` | Run the full applicable suite. |

Package integration, clean-install, upgrade, and infrastructure tests run in external CI and may require protected credentials. Do not substitute a local chart-only render for required cross-package evidence.

## Big Bang Integration

The bootstrap Kustomization installs this chart as a Flux HelmRelease. The chart then creates separately pinned sources and releases for enabled packages. A package change can therefore require coordinated work in three places:

- The package repository owns its chart implementation, package values, tests, upgrade notes, and Big Bang-specific package additions.
- This repository owns package enablement, source pins, dependency ordering, global-to-package value mapping, and umbrella integration.
- The upstream project owns the complete product and upstream chart configuration surface.

For upstream passthrough configuration, document only the parent entry point and link to version-appropriate upstream values. Do not copy nested upstream keys into umbrella or package documentation.

## Upgrade and Release Workflow

- Normal merge requests do not change `chart/Chart.yaml`'s version; umbrella releases follow the [release schedule](README.md#release-schedule).
- Merge request CI tests clean install and upgrade from `master`. Protected tags trigger artifact preparation, signing, and publication through the [CI workflow](docs/community/development/ci-workflow.md).

## Integration Test Environment

- The external merge request pipeline uses an ephemeral k3d cluster for install, upgrade, reconciliation, and endpoint checks; it is the authoritative umbrella integration evidence.
- Cross-repository branches use the [package branch test workflow](docs/community/development/test-package-against-bb.md). The `test-ci::infra` label enables manually authorized jobs that create cloud resources.

## Safety and Credentials

- Defaults, fixtures, rendered output, logs, and commits must not contain real credentials, private keys, license data, or production endpoints.
- `scripts/template-all.sh` is networked, hard-resets its source cache, adds Helm repositories, and may authenticate to registries.
- `scripts/install_flux.sh`, `scripts/sync.sh`, `scripts/remove-ns-finalizer.sh`, and restart modes in `scripts/istio-sidecars.sh` mutate the cluster selected by the active kubeconfig.
- GitLab triage scripts can create or modify issues and provide dry-run modes.

## Generated Files

- `chart/package-metadata.yaml` generates canonical schema blocks in `chart/values.schema.json` and package metadata in `scripts/migrate-values-3-to-4.sh` through `scripts/generate-package-schemas.sh --write`.
- `chart/Chart.yaml`, `chart/values.yaml`, and `docs/configuration/base-config.md.gotmpl` generate `docs/configuration/base-config.md` through `scripts/generate-values-reference.sh --write`.
- `base/flux/gotk-components.yaml` is generated by Flux according to `renovate.json`.
