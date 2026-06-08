# 10. Upstream Values README Documentation

Date: 2026-06-04

## Status

Accepted

## Context

Big Bang package charts often use the passthrough chart pattern described in [ADR 5](./0005-passthrough-chart.md). In this pattern, the package `values.yaml` contains Big Bang specific values and selected overrides that are passed to the bundled upstream chart, commonly under an `upstream` key.

Package `README.md` values tables are generated from `values.yaml` comments with `helm-docs`. A `# --` comment documents the next value key and causes that key to appear in the generated values table. When `# --` comments are added to nested keys under `upstream`, `helm-docs` adds those subkeys to the table as separate rows.

That behavior is useful for Big Bang owned values, but it is not desirable for upstream passthrough sections. The upstream chart owns the full configuration surface, and that surface changes during upstream chart upgrades. Duplicating upstream subkeys in Big Bang README tables increases maintenance churn, makes the table harder to scan, and can leave stale documentation in the package when the bundled upstream chart changes.

Some upstream passthrough overrides are still Big Bang maintained values. Container image overrides are the most common example: Big Bang packages may need to set Iron Bank image repositories and explicit tags or digests under the upstream chart's native image keys so image provenance, upgrades, and generated image metadata remain deterministic.

## Decision

For package values that are passed through to a bundled upstream chart, document the parent passthrough key as a single row in the generated README values table. The row must point users to the upstream chart values file on GitHub when one is available.

Use `# @default -- ...` on the documented passthrough parent to control the generated table's default-value display. This `@default` annotation is a `helm-docs` rendering instruction only. It is not a statement that Big Bang is copying upstream defaults unchanged. The text should make clear that the complete upstream values are linked and that the Big Bang package values file contains selected overrides.

Example:

```yaml
# -- Values passed to [the upstream chart- <version-or-branch>](https://github.com/<upstream-org>/<upstream-repo>/blob/<version-or-branch>/<chart-path>/values.yaml).
# @default -- See upstream values; this package file includes only Big Bang overrides.
upstream:
  someOverride: value
```

Remove existing `# --` comments from subkeys nested under the upstream passthrough key and do not add new ones. If maintainers need context near an override, use regular YAML comments that do not follow the `helm-docs` documentation format.

When a passthrough chart needs container image overrides, explicitly pin the image tag or digest. Do not introduce parallel Big Bang owned image keys only to avoid nesting under `upstream`, and do not rely on upstream implicit defaults such as `.Chart.AppVersion` because Big Bang needs deterministic image references.

Example:

```yaml
# -- Values passed to [the upstream chart](https://github.com/<upstream-org>/<upstream-repo>/blob/<version-or-branch>/<chart-path>/values.yaml).
# @default -- See upstream values; this package file includes only Big Bang overrides.
upstream:
  image:
    registry: registry1.dso.mil
    repository: ironbank/example/package
    tag: 1.2.3
```

This convention applies to upstream passthrough sections, such as `upstream` or an equivalent chart alias. It does not remove the expectation that Big Bang specific values are documented individually in the generated README values table.

## Consequences

README values tables will stay focused on Big Bang specific values and package-level override entry points instead of duplicating the upstream chart's full values schema.

Users will have a visible table row that points to the upstream chart values on GitHub for the full upstream configuration surface.

Package maintainers will have less README churn during upstream chart upgrades because nested upstream comments will not cause individual upstream subkeys to be generated as table rows.

Big Bang overrides nested under the upstream passthrough key will no longer be individually listed in the README table. Reviewers and users who need those details must inspect the package `values.yaml` and the linked upstream values file.

Maintainers must keep the upstream values link accurate for the chart source and version strategy used by the package.

Maintainers must also keep pinned upstream image overrides aligned with chart upgrades, image metadata annotations, and Renovate configuration. This adds review responsibility during package upgrades, but prevents accidental drift from upstream image defaults and keeps Big Bang deployments on the intended images.

