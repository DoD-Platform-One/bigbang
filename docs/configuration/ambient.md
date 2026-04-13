# Configuring Istio Ambient Mode in Big Bang

> **WARNING:** Ambient mode is currently in an **alpha state** within Big Bang. It is not fully integrated and is **not recommended for production use**. Expect potential breaking changes in future releases.
>
> **NOTE:** During the alpha phase, the global `istio.ambient.enabled` flag only deploys the required ambient infrastructure (ztunnel, istio-cni, gateway-api). Individual packages must be explicitly configured to participate in the ambient mesh until they have been validated. In future releases, the global ambient flag will automatically opt packages into ambient mode.

[[_TOC_]]

## Overview

Big Bang supports [Istio Ambient Mode](https://istio.io/latest/docs/ambient/overview/), a sidecar-less data plane architecture that provides mTLS and traffic management without requiring sidecar proxies in application pods. Instead of injecting Envoy sidecars, ambient mode uses a node-level ztunnel component to handle Layer 4 (L4) traffic.

## Enabling Ambient Mode

To enable ambient mode globally, set the `istio.ambient.enabled` flag in your values:

```yaml
istio:
  ambient:
    enabled: true
```

## Packages Enabled by the Global Ambient Flag

When `istio.ambient.enabled` is set to `true`, Big Bang automatically enables the following packages:

| Package         | Description                                                              |
| --------------- | ------------------------------------------------------------------------ |
| **ztunnel**     | The node-level proxy that handles L4 traffic and mTLS in ambient mode    |
| **istio-cni**   | The CNI plugin required for traffic interception in ambient mode         |
| **gateway-api** | Kubernetes Gateway API CRDs used by ambient mode for traffic management  |

You do not need to explicitly enable these packages when using the global ambient flag.

## Example Configuration

A minimal configuration to enable ambient mode:

```yaml
istio:
  ambient:
    enabled: true

# The following packages are automatically enabled,
# but you can still override their values if needed:
# ztunnel:
#   values: {}
# istioCNI:
#   values: {}
# gatewayAPI:
#   values: {}
```

## Platform-Specific Configuration

### istio-cni

When enabling ambient mode, `istio-cni` is automatically deployed. Depending on your Kubernetes platform, you may need to customize the CNI configuration. Common platforms that require specific settings include:

- **OpenShift**: Requires specific CNI bin/conf directories
- **K3s/K3d**: Uses non-standard CNI paths
- **GKE/EKS/AKS**: May have platform-specific networking requirements

Refer to the [upstream istio-cni values](https://github.com/istio/istio/blob/master/manifests/charts/istio-cni/values.yaml) for available configuration options. Override these in your Big Bang values:

```yaml
istioCNI:
  values:
    cni:
      cniBinDir: /opt/cni/bin       # Customize for your platform
      cniConfDir: /etc/cni/net.d    # Customize for your platform
```

## Additional Resources

### Big Bang Documentation

- [ztunnel Package](../packages/core/ztunnel.md)
- [Gateway API Package](../packages/core/gateway-api.md)

### Upstream Istio Documentation

- [Istio Ambient Mode Overview](https://istio.io/latest/docs/ambient/overview/)
- [Ambient Mode Architecture](https://istio.io/latest/docs/ambient/architecture/)
- [Migrating to Ambient Mode](https://istio.io/latest/docs/ambient/install/)
