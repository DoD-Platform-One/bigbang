# Big Bang 4.0: The Next Evolution of the Platform

Big Bang 4.0 is planned for October 2026. This release brings together sustained
work across the Big Bang value stream to make secure Kubernetes platforms
easier to operate, configure, and extend.

Many of these capabilities were introduced, evaluated, and refined throughout
the Big Bang 3.x lifecycle. Big Bang 4.0 marks the point where that work comes
together in four foundational areas: service mesh architecture, shared package
integration, umbrella package configuration, and Kubernetes policy
enforcement.

This article focuses on the value those capabilities provide. For detailed
release and upgrade information, visit the
[Big Bang release notes](https://docs-bigbang.dso.mil/latest/release-notes/) and
[Big Bang documentation](https://docs-bigbang.dso.mil/latest/).

## Istio Ambient Mesh Becomes the Default

Big Bang 4.0 makes **Istio Ambient Mesh the default Istio configuration**.

Ambient Mesh provides service-mesh security without requiring an Envoy sidecar
in every application pod. Instead, a shared, node-level proxy called `ztunnel`
provides Layer 4 connectivity, identity, and mutual TLS for workloads in the
mesh. When an application needs Layer 7 behavior, such as HTTP-aware policy or
routing, waypoint proxies can provide it selectively rather than imposing that
cost on every workload.

This architecture offers several practical benefits:

- **Lower workload overhead:** Proxy resource consumption no longer grows with
  every application pod in the mesh.
- **Simpler operations:** Application pods do not need to be restarted solely
  to receive routine proxy updates.
- **Easier application onboarding:** Mission applications can join the mesh
  without modifying pod specifications to inject a sidecar.
- **Selective Layer 7 capabilities:** Teams can apply deeper traffic processing
  where it provides value while using the lighter Layer 4 data plane elsewhere.

Supporting Ambient required coordinated work across the Big Bang platform.
Istio CNI, `ztunnel`, and Kubernetes Gateway API provide the underlying mesh
capabilities. Big Bang also updated its network and authorization policy model
to account for traffic carried over the HBONE tunnel. Together, these changes
preserve secure-by-default traffic controls as the data plane moves away from
sidecars.

Ambient first became available as an opt-in beta in Big Bang 3.23 and reached
General Availability in Big Bang 3.32. It remains opt-in for the rest of the
3.x lifecycle before becoming the default in 4.0. We recommend that users begin
migrating now with Big Bang 3.32 or later, starting in a development or test
environment and validating mission-specific traffic and integrations before
production. Migrating ahead of 4.0 lets teams evaluate the mesh change
independently from the major-version platform upgrade.

Making Ambient the default does not remove sidecar mode: Big Bang 4.0 continues
to support sidecar configuration so users can upgrade the platform without
also being required to migrate their service mesh. If a mission environment
uncovers an Ambient issue, sidecar mode provides a supported escape hatch while
that issue is addressed. Maintaining both modes adds development and testing
cost, so Big Bang may reconsider sidecar support in a future release through a
separate deprecation decision. Read
[ADR 13](../docs/community/adrs/0013-retain-istio-sidecar-support-in-big-bang-4.md)
for the complete decision.

Authservice is also supported with Ambient through waypoint proxies, which
provide the Layer 7 enforcement that `ztunnel` cannot. When an inbound route
enables Authservice, `bb-common` creates a shared waypoint for the package
namespace along with the route's JWT validation, external-authorization, deny
backstop, and required network policies. The consuming package enrolls the
protected Service onto that waypoint so both ingress and in-mesh traffic follow
the intended policy path. Big Bang's Monitoring and Thanos integrations use
this route-scoped waypoint model for SSO-protected services.

Read the [Ambient Mesh adoption overview](./istio-ambient-beta.md) to learn more
about the architecture, or consult the
[Ambient migration guide](../docs/migration/migrating-istio-to-ambient.md) for
detailed preparation and compatibility information.

## A Shared Integration Foundation with `bb-common`

As the Big Bang package ecosystem grew, packages often implemented the same
platform concerns in different ways. Network policies were a clear example:
similar rules could have different configuration shapes, defaults, and
override behavior depending on the package. That duplication made package
integration harder to understand, test, and maintain.

`bb-common` provides a shared Big Bang integration layer for these cross-cutting
concerns. The bb-common implementation focused on network policy, reusable
definitions, consistent default-deny behavior, and a concise domain-specific
language for expressing communication between workloads. Policy configuration
remains visible in package values, making the intended security boundaries
easier to review and audit.

This shared behavior is especially important for Ambient Mesh. Workloads using
Ambient communicate through the HBONE tunnel, and their network and
authorization policies must account for that traffic without weakening
segmentation. Centralizing those patterns in `bb-common` allows Big Bang to
apply them consistently instead of solving the same problem independently in
every package.

More broadly, a shared integration layer means that improvements and security
fixes can be implemented once and adopted across the package ecosystem. It
reduces duplicated templates, makes package behavior more predictable, and
provides one place to build comprehensive tests for common platform behavior.
Read [Streamlining Integration with `bb-common`](./streamlining-integration-with-bb-common.md)
for a deeper look at the design and network-policy model.

### From Helm Library Chart to Regular Subchart

Big Bang is also standardizing how packages consume `bb-common`. Packages
initially used it as a Helm library chart, selectively calling shared templates
through package-specific `include` helpers. In that model, Big Bang-specific
values such as `istio`, `networkPolicies`, and `routes` were supplied at the top
level of the package's values.

Packages are moving to consume `bb-common` as a regular Helm subchart. This
places its configuration under a scoped `bb-common` key and uses Helm's standard
dependency behavior. The Big Bang umbrella currently supports both shapes
while integrated packages complete the transition.

The move makes package integration simpler, safer, and more consistent. As a
regular subchart, `bb-common` can enforce a strict values schema and catch
incorrectly structured configuration before deployment. This reduces the risk
of accepting configuration that is valid YAML but silently has no effect. It
also removes the need for packages to add integration-specific include
templates: package authors can add `bb-common` as a standard chart dependency
and supply values through its scoped configuration.

The result is less custom integration code, clearer ownership of Big
Bang-specific behavior, and a common dependency model across the package
ecosystem. It also brings integrated packages into alignment with the subchart
model already used by team-maintained packages. The complete architectural
decision is recorded in
[ADR 14](../docs/community/adrs/0014-consume-bb-common-as-a-helm-subchart.md).

During the transition, the umbrella chart merges common defaults with user
overlays and supplies the correct values shape for each package. Packages that
have migrated receive a nested `bb-common` configuration, while packages still
using the library chart continue to receive the legacy flat values. Every Big
Bang integrated and team-maintained package will complete this migration for
4.0, allowing the umbrella to remove its temporary compatibility logic and use
the standard subchart model consistently.

This transition changes the values shape for these packages, so existing users
will need to migrate their package overrides. For the 4.0 upgrade, users will be
able to use Big Bang's
[3-to-4 values migration script](../scripts/migrate-values-3-to-4.sh) for both
breaking configuration changes. In one migration, the script will move legacy
top-level and `addons.<name>` package configuration into the consistent
`packages.<name>` map and rewrite integrated and team-maintained package
overrides from the Helm library-chart values shape to the scoped `bb-common`
subchart shape. Users should review and validate the generated values before
deployment.

Bring your own packages and mission applications remain under their owners'
control: packages already using `bb-common` as a subchart do not need this
consumption-model migration, while owners using the library pattern remain
responsible for updating their package and values. Big Bang recommends subchart
consumption when an owner can modify or wrap the application chart. The
[`bb-common` integration guide](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/INTEGRATION_GUIDE.md?ref_type=heads)
also documents Argo CD and Kustomize alternatives for applications where adding
the subchart is not possible.

## One Consistent Way to Configure Every Package

Big Bang has historically exposed package configuration through three different
locations. Core packages use top-level keys such as `monitoring`, add-on
packages use keys such as `addons.gitlab`, and user-supplied packages use
`packages.<name>`. As a result, users and automation must know how Big Bang
categorizes a package before they can locate its configuration.

Big Bang 4.0 introduces one canonical model: built-in and user-supplied packages
are configured under **`packages.<name>`**.

For example, package enablement moves from separate core and add-on locations:

```yaml
# Big Bang 3.x legacy paths
monitoring:
  enabled: true
addons:
  gitlab:
    enabled: true
packages:
  confluence:
    enabled: true
  bringYourOwnPackage:
    enabled: true
```

to one consistent package map:

```yaml
# Big Bang 4.x unified package configuration
packageConfiguration:
  version: v1
packages:
  monitoring:
    enabled: true
  gitlab:
    enabled: true
  confluence:
    enabled: true
  bringYourOwnPackage:
    enabled: true
```

This provides one predictable location for every deployable package. Automation
no longer needs special logic for core, add-on, and user-supplied packages, and
a package can change category without moving its public configuration path.
Global platform configuration—including domain, registry credentials, shared
network-policy settings, and shared Istio configuration—remains at the top
level.

The unified model is backed by a repository-owned package metadata catalog.
That catalog defines canonical package identities and generates the relevant
schema and migration mappings. It allows Big Bang to detect ambiguous package
names and resource-name collisions earlier while reducing duplicated package
metadata across the umbrella chart and its tooling.

Users can adopt the unified contract during the 3.x lifecycle with
`packageConfiguration.version: v1`. In Big Bang 4.0, `v1` becomes the default
and supported package contract, and the legacy top-level and `addons.<name>`
package paths are removed. Read
[ADR 11](../docs/community/adrs/0011-unified-package-configuration-and-metadata.md)
for the design decision and the
[package values migration guide](../docs/migration/migrating-package-values-for-bb4.0.md)
when preparing existing configuration.

## Kyverno Policies Move to CEL

Big Bang 4.0 modernizes its policy foundation by moving the
`kyverno-policies` package away from Kyverno's legacy `ClusterPolicy` resources
and onto its purpose-built, CEL-based policy APIs.

Big Bang currently integrates Kyverno v1.19, which still supports
`ClusterPolicy`. Upstream Kyverno identifies v1.19 as the final release with
full support for its legacy policy types: `ClusterPolicy` and `Policy` are
officially deprecated in v1.19 and will be removed in v1.20. Kyverno currently
estimates the v1.20 release for November 2026, and Big Bang expects to integrate
Kyverno v1.20 through the Kyverno package in November. Moving Big Bang policies
to CEL as part of 4.0 prepares users for that package update before the legacy
resources disappear. See Kyverno's
[v1.19 release announcement](https://kyverno.io/blog/2026/08/20/announcing-kyverno-release-1.19/)
and [policy-type deprecation schedule](https://kyverno.io/docs/policy-types/overview/#deprecation-schedule-for-legacy-types)
for the upstream timeline.

[Common Expression Language](https://kubernetes.io/docs/reference/using-api/cel/)
(CEL) is used throughout Kubernetes for expressions and admission control. By
adopting Kyverno's CEL policy types, Big Bang aligns its policy implementation
with that broader Kubernetes direction and moves from one resource that mixes
multiple rule types to APIs with clearer responsibilities:

- `ValidatingPolicy` allows or rejects resources during admission.
- `MutatingPolicy` modifies resources.
- `GeneratingPolicy` creates related resources.
- `ImageValidatingPolicy` verifies container images.

Big Bang's built-in policies retain recognizable names and package-level
configuration even though the underlying resource types and expression model
change. This preserves a familiar policy catalog while moving its implementation
onto a more modern foundation.

Policy exceptions evolve with the policy resources. Legacy exceptions referred
to policy and rule names and selected resources through the older match model.
The CEL-based `PolicyException` uses `policyRefs` to identify policies and CEL
`matchConditions` to select resources. Big Bang provides package-specific
exceptions for workloads that legitimately require elevated permissions or
access to the Kubernetes API.

The new configuration schema rejects known legacy fields so incompatible
overrides fail visibly instead of being silently ignored. Users who deploy the
default policy configuration receive the updated policy foundation through Big
Bang. Users who customize policies, exclusions, or exceptions should review the
[upstream CEL migration guide](https://kyverno.io/docs/guides/migration-to-cel/)
before adopting 4.0 and follow the Big Bang release notes for package-specific
guidance.

## Preparing for Big Bang 4.0

These capabilities change important platform defaults and configuration
contracts. Existing users should review the Big Bang 4.0 release notes and the
linked migration guides before upgrading. Detailed compatibility requirements,
breaking changes, and step-by-step actions will be maintained in those sources
rather than repeated here.

<!-- TODO(owner): Add the final Big Bang 4.0 release-notes link when it is
available. -->

## Built with the Community

Big Bang 4.0 replaces bespoke and legacy patterns with platform foundations
that are simpler, more consistent, and aligned with Kubernetes and Helm
standards. Ambient Mesh reduces the operational weight of the service mesh,
`bb-common` makes secure package integration reusable, unified package
configuration gives users one coherent contract, and CEL provides a modern
policy foundation.

Together, these capabilities reduce platform friction so teams can spend more
time securely delivering mission applications.

Thank you to the package maintainers, contributors, testers, and community
members whose feedback shaped this work. Follow the
[Big Bang release notes](https://docs-bigbang.dso.mil/latest/release-notes/) and
[Big Bang documentation](https://docs-bigbang.dso.mil/latest/) for the latest
information as the October 2026 release approaches.
