# 13. Retain Istio Sidecar Support in Big Bang 4.0

Date: 2026-09-08

## Status

Accepted

## Context

Big Bang 4.0 makes Istio Ambient Mesh the default mesh configuration. Ambient
removes the requirement for an Envoy sidecar in every application pod and uses
node-level `ztunnel` proxies for Layer 4 connectivity, identity, and mutual TLS.
Optional waypoint proxies provide Layer 7 capabilities when applications need
them.

Ambient support was introduced as an opt-in beta in Big Bang 3.23 and reached
General Availability in Big Bang 3.32. It remains opt-in for the rest of the
3.x lifecycle so package maintainers and users can migrate and evaluate the new
data-plane model before it becomes the default. Big Bang-managed packages have
added Ambient-specific namespace enrollment, HBONE network-policy behavior,
Layer 4 authorization policies, and waypoint integration for Layer 7 use cases
such as Authservice.

Mission environments can contain workloads, network paths, and application
behaviors that are not represented fully in Big Bang's integration test
environment. Additional Ambient issues may therefore be discovered as users
migrate production-like environments. If Big Bang 4.0 removed sidecar support,
users encountering one of those issues would have to complete their mesh
migration before they could adopt the other security fixes, package updates,
and platform capabilities delivered by 4.0.

Keeping both integration patterns has a cost. Package defaults, umbrella value
translation, policy behavior, documentation, and integration tests must account
for both sidecar and Ambient traffic paths. That testing and maintenance burden
will continue while both modes are supported.

## Decision

Big Bang 4.0 will support both Istio Ambient and sidecar mesh configurations.
Ambient will be the default for new 4.0 deployments, but an existing user may
upgrade to Big Bang 4.0 while continuing to use the sidecar configuration.
Migration to Ambient is not a prerequisite for adopting Big Bang 4.0.
Users are nevertheless encouraged to begin migrating on Big Bang 3.32 or later
so they can validate mission-specific behavior independently from the 4.0
platform upgrade.

Sidecar support serves as a compatibility path and a temporary escape hatch for
mission environments that encounter an Ambient issue that would otherwise
block the platform upgrade. Sidecar mode remains a supported configuration,
not an untested legacy fallback, for as long as this decision remains in
effect.

While both modes are supported:

- the umbrella chart will continue to select and pass the appropriate sidecar
  or Ambient values to integrated packages;
- package integrations will preserve the resources and configuration required
  by each supported traffic path;
- clean-install, upgrade, and relevant package integration testing will cover
  both modes; and
- user documentation will identify mode-specific behavior and limitations.

This decision does not commit Big Bang to maintaining sidecar mode
indefinitely. The project may remove it in a future release after evaluating
Ambient adoption, known mission-environment blockers, and the ongoing cost of
maintaining two mesh integration patterns. A removal will require a separate
architectural decision, an announced deprecation window, and migration guidance.

## Alternatives Considered

### Remove sidecar support in Big Bang 4.0

This would reduce the implementation and testing matrix and establish Ambient
as the only mesh integration pattern immediately. It was rejected because it
would couple the Big Bang 4.0 platform upgrade to every user's successful
Ambient migration. An environment-specific Ambient issue could prevent a user
from adopting the rest of the release.

### Keep Ambient opt-in after Big Bang 4.0

This would minimize disruption for existing deployments but delay adoption of
the new mesh architecture and make sidecar behavior the continuing default. It
was rejected because Ambient has been introduced and refined during the 3.x
lifecycle specifically to become the default in Big Bang 4.0.

## Consequences

Users can adopt Big Bang 4.0 independently from their Ambient migration. Teams
that are ready can use the new default, while teams that uncover a blocking
issue can continue temporarily with the supported sidecar data plane. This
reduces upgrade risk and allows users to receive the other improvements in 4.0
without changing two foundational layers at the same time.

Big Bang maintainers must continue accounting for two mesh integration
patterns. Changes to Istio, `bb-common`, Authservice, network policies,
authorization policies, and package connectivity may require separate sidecar
and Ambient behavior and validation. This increases development time, CI usage,
documentation complexity, and the chance of mode-specific regressions.

Making Ambient the default while retaining sidecar support also requires clear
documentation. Users must be able to identify which mode they are running, how
to preserve sidecar mode during a 4.0 upgrade, and which capabilities or
limitations differ between the modes.

The project can revisit sidecar support when operational evidence shows that
Ambient meets supported mission use cases and the value of retaining the
fallback no longer justifies its maintenance cost.

## References

- [Configuring Istio Ambient Mode](../../configuration/ambient.md)
- [Migrating from Sidecar Mode to Ambient Mode](../../migration/migrating-istio-to-ambient.md)
- [Istio Ambient Mesh in Big Bang: From Beta to GA](../../../blog/istio-ambient-beta.md)
