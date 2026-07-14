# Big Bang Common Library Integration

The Big Bang Common Library ([bb-common](https://repo1.dso.mil/big-bang/product/packages/bb-common)) provides standardized Helm templates for integrating packages with Big Bang's security and networking features.

## Prerequisites

- A [Big Bang project containing the upstream Helm chart](./upstream.md)
- bb-common added as a chart dependency in `Chart.yaml`

## What bb-common Provides

- **Istio Service Mesh** - Virtual services, sidecars, gateways
- **Network Policies** - Kubernetes network traffic control
- **Authorization Policies** - Service-to-service access control
- REGISTRY_ONLY mode and default-deny policies and other good defaults

## Integration Steps

### 1. Add bb-common Dependency

Add to your `Chart.yaml`:

```yaml
dependencies:
  - name: bb-common
    repository: oci://registry1.dso.mil/bigbang
    version: "x.x.x"
```

### 2. Service Mesh Integration

**See:** [bb-common Istio Documentation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/tree/main/docs/istio) and [Routes Documentation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/tree/main/docs/routes)

- Enable Istio sidecar injection on your namespace, not needed if deploying using Big Bang umbrella, i.e. `packages`
- Use `{{- include "bb-common.istio.render" . }}` to render the configured PeerAuthentication, Sidecar, ServiceEntry, and AuthorizationPolicy resources
- Use `{{- include "bb-common.routes.render" . }}` to render inbound and outbound routes
- Configure the package's `istio`, `networkPolicies`, and `routes` values following the current bb-common patterns

### 3. Network Policies

**See:** [bb-common Network Policies Documentation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/tree/main/docs/network-policies)

- Use `{{- include "bb-common.network-policies.render" . }}` in templates
- Configure `networkPolicies` values section
- Add custom policies via `ingress` and `egress` as needed

### 4. Authorization Policies

**See:** [bb-common Authorization Policies Documentation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/tree/main/docs/authorization-policies)

- Configure authorization policies under `istio.authorizationPolicies`
- Set `istio.authorizationPolicies.generateFromNetpol: true` to have `bb-common.network-policies.render` generate corresponding Istio `AuthorizationPolicy` resources from identity-bearing network-policy rules
- Include identities in network-policy entries using the `service-account@namespace/pod` form when service-account authentication is required
- Use `bb-common.istio.render` for default and custom Istio authorization policies, and add package-specific policies through `istio.authorizationPolicies.custom`; use the bb-common documentation as the source of truth for supported fields

### Umbrella compatibility

Package charts should expose the current bb-common value structure described above. The Big Bang umbrella still accepts `istio.hardened` settings as a compatibility and global-hardening input, then translates those settings into current package values such as `istio.sidecar`, `istio.serviceEntries`, and `istio.authorizationPolicies`. Do not model a new package's standalone values API on the legacy `istio.hardened` structure.

## Additional Resources

- [bb-common Main Documentation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/tree/main/docs)
- [bb-common Resource Graph](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/tree/main/docs/RESOURCE_GRAPH.md)
