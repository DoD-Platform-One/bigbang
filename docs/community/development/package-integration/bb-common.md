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
- Use `{{- include "bb-common.istio.virtualService" . }}` for virtual services
- Configure Istio values following bb-common patterns

### 3. Network Policies

**See:** [bb-common Network Policies Documentation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/tree/main/docs/network-policies)

- Use `{{- include "bb-common.networkPolicy" . }}` in templates
- Configure `networkPolicies` values section
- Add custom policies via `ingress` and `egress` as needed

### 4. Authorization Policies

**See:** [bb-common Authorization Policies Documentation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/tree/main/docs/authorization-policies)

- Use `{{- include "bb-common.authorizationPolicy" . }}` for authorization policies
- Configure `istio.hardened` values section
- Add policies via `istio.authorizationPolicies.generateFromNetpol`, and prefix the netpols with `example-service-account@` to require service account authentication

## Additional Resources

- [bb-common Main Documentation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/tree/main/docs)
- [bb-common Resource Graph](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/tree/main/docs/RESOURCE_GRAPH.md)
