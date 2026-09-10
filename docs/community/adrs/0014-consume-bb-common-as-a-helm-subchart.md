# 14. Consume `bb-common` as a Helm Subchart

Date: 2026-09-08

## Status

Accepted

## Context

[ADR 12](./0012-standard-package-architecture.md) establishes `bb-common` as
the standard implementation for shared Big Bang security and networking
resources. Packages have historically consumed those capabilities through the
library-chart pattern: the package declares `bb-common` as a dependency, adds
thin templates that call its render interfaces with Helm `include`, and exposes
Big Bang-owned `istio`, `networkPolicies`, and `routes` values at the package
chart root.

That pattern centralizes template implementation, but each package must still
wire the render interfaces into its own templates. It also places
`bb-common` configuration in the consuming chart's values namespace. Helm
cannot use the complete `bb-common` values schema at that location without the
consumer copying or synchronizing the schema, so incorrectly structured values
can be accepted but have no effect.

The `bb-common` chart is an application chart that can render its supported
resources directly when installed as a regular Helm subchart. In that model,
Helm scopes its values under the dependency key and validates them against
`bb-common`'s own `values.schema.json`. Big Bang team-maintained packages
already use this subchart consumption model. Applying it to integrated packages
will establish one package-integration pattern across the Big Bang-owned
ecosystem.

The Big Bang umbrella currently supports a package-by-package transition. Its
`values-secret` helper can supply the legacy flat values shape to a library
consumer or nest the same effective `istio`, `networkPolicies`, and `routes`
configuration under `bb-common` for a migrated subchart consumer. This
compatibility logic is useful during Big Bang 3.x, but it is not intended to
become a permanent package-specific branch in the umbrella chart.

## Decision

Every Big Bang integrated package and team-maintained package will consume
`bb-common` as a regular Helm subchart for Big Bang 4.0. The dependency will
render the supported shared resources directly, and its configuration will be
scoped under the `bb-common` values key.

Packages will no longer add thin Helm templates that call `bb-common` render
interfaces for capabilities supported by the subchart. Package-specific
templates remain appropriate only when a requirement cannot be represented by
the `bb-common` values contract.

This decision refines and supersedes the library-consumption details in ADR
12's **Common Big Bang resources** section. ADR 12's remaining decisions about
wrapper charts, unmodified upstream dependencies, package portability, and the
boundary between package and umbrella responsibilities remain in effect.

### Values contract

The package values shape changes from library-style root keys:

```yaml
istio: {}
networkPolicies: {}
routes: {}
```

to values scoped to the subchart dependency:

```yaml
bb-common:
  istio: {}
  networkPolicies: {}
  routes: {}
```

This is a breaking package values change. Users of integrated and
team-maintained packages must migrate their package overrides to the nested
shape when adopting the 4.0-compatible package versions.

The Big Bang 3-to-4 migration utility will combine this values migration with
the unified package-configuration migration defined by
[ADR 11](./0011-unified-package-configuration-and-metadata.md). For known
built-in packages, the utility will move legacy `bb-common` values into the
new subchart scope while it moves package configuration under
`packages.<name>`. Users must review and validate the generated values before
deploying them.

### Transition and end state

Integrated packages may migrate incrementally during Big Bang 3.x. Until every
integrated package has migrated, the umbrella chart will use its
`bbCommonSubchart` compatibility switch to supply the values shape expected by
each package.

All integrated packages must complete the transition before Big Bang 4.0. Once
they have migrated, the umbrella chart will always supply the nested
`bb-common` values block. The temporary `bbCommonSubchart` argument, legacy flat
values handling, and library-era `istio.injection` translation will be removed.

### Bring your own packages (BYO) and mission applications

This decision does not prescribe how independently owned BYO packages or
mission applications consume `bb-common`. Their owners remain responsible for
their package integration. Big Bang recommends using `bb-common` as a subchart
when an owner can modify the application chart or place an upstream chart
behind a passthrough wrapper. When that is not possible, the
[`bb-common` integration guide](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/INTEGRATION_GUIDE.md?ref_type=heads)
documents alternative Argo CD multi-source and Kustomize with Helm integration
patterns.

The Big Bang migration utility will not infer or rewrite the internal values
contract of an unknown user-supplied package. Owners using the library pattern
remain responsible for deciding how to migrate their package and values and
should evaluate the recommended subchart model. Owners already using the
subchart pattern do not need a consumption-model migration. Any continued
availability of the library interfaces is governed by the `bb-common` project
rather than this decision.

## Alternatives Considered

### Continue using the library-chart pattern for integrated packages

This would avoid a breaking values change and preserve the existing package
templates. It was rejected because it retains duplicated integration wiring,
requires consumers to synchronize schema coverage, and leaves Big Bang-owned
packages on different consumption models.

### Allow either pattern indefinitely for integrated packages

This would let each package choose its preferred integration but would preserve
the umbrella's package-specific compatibility branch and require both patterns
to remain part of Big Bang's integration and testing model. It was rejected in
favor of one standard contract for packages owned by Big Bang.

### Copy `bb-common` schemas into every library consumer

This could improve validation without changing the rendering model, but the
copied schemas could drift from the chart that owns the values contract. It
would also leave the package-specific include templates in place. Native
subchart scoping and validation provide a simpler ownership model.

## Consequences

Packages gain native validation from `bb-common`'s strict values schema.
Malformed or incorrectly nested configuration can fail during Helm validation
instead of being accepted and silently failing to produce the intended
resources.

Package repositories contain less integration boilerplate because they no
longer need thin templates for each `bb-common` render interface. Adding the
dependency and configuring its scoped values becomes the standard integration
path. Shared behavior and schema changes remain owned and tested in the
`bb-common` repository.

Users must migrate package values when moving to 4.0-compatible integrated and
team-maintained package versions. Combining this rewrite with the unified
package migration gives users one supported transformation rather than
requiring unrelated manual edits in separate upgrade steps.

The Big Bang team must coordinate package releases, umbrella mappings, schemas,
tests, documentation, and the migration utility so all integrated packages
reach the subchart model before 4.0. During the 3.x transition, both consumption
shapes remain in the umbrella test matrix.

BYO package and mission-application owners retain flexibility, but they also
retain responsibility for validating their chosen `bb-common` integration and
performing any package-specific migration.

## References

- [ADR 11: Unified Package Configuration and Package Metadata](./0011-unified-package-configuration-and-metadata.md)
- [ADR 12: Standard Big Bang Package Architecture](./0012-standard-package-architecture.md)
- [`bb-common` integration overview](../../../blog/streamlining-integration-with-bb-common.md)
- [`bb-common` integration guide for application owners](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/INTEGRATION_GUIDE.md?ref_type=heads)
- [Migrating package values for Big Bang 4.0](../../migration/migrating-package-values-for-bb4.0.md)
