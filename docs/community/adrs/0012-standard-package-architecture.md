# 12. Standard Big Bang Package Architecture

Date: 2026-08-31

## Status

Accepted

## Context

[ADR 2](./0002-package-standardization.md) standardized the repository structure of Big Bang packages around a package template. That structure assumed that package repositories would maintain many Big Bang-specific Kubernetes resources directly, including network policies and Istio resources.

[ADR 5](./0005-passthrough-chart.md) subsequently established the passthrough Helm chart pattern. Under that pattern, a Big Bang package wraps an upstream Helm chart as a dependency instead of maintaining a modified copy of the upstream chart. ADR 5 also anticipated consolidating commonly used Big Bang templates into a shared repository.

The `bb-common` chart now provides that shared implementation for common security and networking resources. Package charts use its template interfaces to render routes, Istio resources, Kubernetes `NetworkPolicy` resources, and generated Istio `AuthorizationPolicy` resources. This reduces duplicated package templates and gives packages a consistent values interface for Big Bang security controls.

The Big Bang umbrella chart also supplies package values derived from platform-wide configuration and coordinates package deployment using Flux. This has sometimes blurred the boundary between the package chart, its Big Bang integration, and the GitOps controller used by the umbrella chart. A package chart is a Helm artifact and should remain renderable with standard Helm tooling. Flux resources and dependency ordering belong to the umbrella deployment layer rather than to the package chart's rendering contract.

The project needs one current architectural decision that connects package standardization, passthrough charts, `bb-common`, and umbrella integration. Detailed and evolving implementation instructions remain in the package integration documentation.

## Decision

Big Bang packages will use a Helm wrapper chart as their standard package architecture.

### Upstream chart integration

When a supported upstream Helm chart exists, the wrapper chart will consume it as an unmodified Helm dependency. The dependency should normally use the alias `upstream` so that its configuration surface is clearly separated from Big Bang-owned package configuration.

The wrapper chart's `values.yaml` will contain:

- Big Bang-owned values at the wrapper chart root;
- selected secure and operational defaults required by Big Bang;
- explicit Big Bang image overrides; and
- an `upstream` mapping for values passed to the upstream chart.

The project will not maintain a copy of the upstream chart's complete values file or fork its templates when the required integration can be expressed through values, `bb-common`, or a narrowly scoped post-renderer. The documentation convention for the upstream values mapping is defined by [ADR 10](./0010-upstream-values-readme-documentation.md).

When no suitable upstream Helm chart exists, a package may maintain application templates in its wrapper chart. The rest of this decision still applies.

### Common Big Bang resources

Package charts will use `bb-common` as the standard implementation for supported Big Bang security and networking resources. A package integrating with those capabilities will:

- declare `bb-common` as a Helm dependency;
- call the applicable `bb-common` render interfaces from wrapper templates;
- expose the current `istio`, `networkPolicies`, and `routes` values contracts; and
- maintain package-specific templates only for requirements that `bb-common` cannot express.

The `bb-common` chart is the source of truth for its supported values and generated-resource behavior. Package repositories remain responsible for defining the package-specific traffic, identities, routes, and exceptions passed to those interfaces.

Shared behavior should be added to `bb-common` when it is broadly applicable and can be represented without weakening secure defaults. Application-specific behavior should remain in the package wrapper.

### Package portability and GitOps integration

The wrapper chart will render through standard Helm tooling without requiring a Flux `HelmRelease` object to be present. Its upstream and `bb-common` dependencies are Helm dependencies and are not coupled to a particular GitOps controller.

Big Bang's umbrella chart may continue to use Flux to:

- retrieve the package chart;
- create and reconcile its `HelmRelease`;
- compose global defaults with package-specific user overlays;
- order package installation against platform dependencies;
- apply post-render patches; and
- create supporting namespaces, credentials, and secrets.

Those umbrella responsibilities do not make Flux part of the package chart's rendering contract. A package may be rendered or deployed by Helm or another Helm-capable controller when the deployer supplies the equivalent values, prerequisites, supporting resources, and lifecycle ordering.

Package templates should not use Flux custom resources as an input to ordinary rendering. A migration that requires controller-specific release history must be isolated, documented, and must not prevent a normal install or render outside that controller.

### Umbrella integration

The Big Bang umbrella chart remains responsible for translating platform-wide configuration into each package's values. This includes settings such as domain names, gateways, ambient or sidecar mode, authorization-policy enablement, network-policy definitions, registry configuration, monitoring integration, and connections to other enabled packages.

Package wrapper defaults must remain valid when the package is rendered independently. A deployment outside the umbrella does not automatically receive Big Bang's calculated values or supporting resources and must provide them explicitly when equivalent platform integration is required.

Compatibility translations for deprecated values belong in the umbrella chart during their supported migration window. New standalone package values APIs will use the current `bb-common` structures rather than reproduce legacy umbrella values.

## Consequences

Package upgrades will generally require less effort because upstream templates remain owned by the upstream project and shared Big Bang resources remain owned by `bb-common`.

Security and networking configuration will be more consistent across packages. Improvements to common behavior can be adopted through a `bb-common` dependency update instead of being independently reimplemented in every package.

Package repositories will have a smaller standard structure than the structure recorded in ADR 2. Empty directories for independently maintained NetworkPolicies and Istio resources are no longer required when `bb-common` provides those resources. ADR 2 is therefore superseded by this decision.

ADR 5 remains in effect for the passthrough dependency pattern. This decision completes the shared-template direction anticipated by ADR 5 and clarifies the boundary between the wrapper chart and the umbrella's Flux integration.

Users deploying a package outside the Big Bang umbrella gain a controller-independent Helm chart, but they assume responsibility for supplying platform-derived values, required CRDs and controllers, namespaces, credentials, secrets, and deployment ordering.

Some package-specific templates and post-renderers will remain necessary where upstream values and `bb-common` cannot express a requirement. These exceptions add maintenance cost and should be kept narrow, documented, and tested.

The detailed integration process and current template interfaces will continue to evolve in the [package integration documentation](../development/package-integration/index.md) without requiring a new ADR for every compatible implementation change.
