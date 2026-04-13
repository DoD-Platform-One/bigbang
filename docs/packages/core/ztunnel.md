# Ztunnel

## Overview

[Ztunnel](https://istio.io/latest/docs/ambient/overview/) (zero-trust tunnel) is a purpose-built component for Istio's ambient mesh mode. It provides a lightweight, shared proxy that handles Layer 4 (L4) traffic between workloads, enabling mutual TLS (mTLS) encryption and zero-trust security without requiring sidecar proxies.

Ztunnel runs as a DaemonSet on each node and transparently intercepts and encrypts traffic between pods, providing secure communication at the network layer. This approach offers a simpler deployment model compared to sidecar-based service mesh architectures.

```mermaid
flowchart LR
  subgraph Node1["Node 1"]
    Z1[Ztunnel]
    P1[Pod A]
    P2[Pod B]
    P1 --> Z1
    P2 --> Z1
  end

  subgraph Node2["Node 2"]
    Z2[Ztunnel]
    P3[Pod C]
    P4[Pod D]
    P3 --> Z2
    P4 --> Z2
  end

  Z1 <-->|"mTLS<br/>Encrypted"| Z2
```

## Big Bang Touchpoints

### Licensing

Ztunnel is part of the Istio project and is open source, licensed under the [Apache License 2.0](https://github.com/istio/ztunnel/blob/master/LICENSE).

### Installation

Ztunnel is deployed to the `istio-system` namespace. It can be enabled explicitly or is automatically enabled when `istio.ambient.enabled: true` is set in Big Bang values:

```yaml
# Explicit enable
ztunnel:
  enabled: true

# Or via ambient mode (auto-enables ztunnel)
istio:
  ambient:
    enabled: true
```

### Storage

Ztunnel does not require any persistent storage. It operates as an in-memory L4 proxy.

### UI

Ztunnel does not have a dedicated UI. Observability is provided through:

- **Kiali**: Visualize mesh traffic and ztunnel connectivity
- **Grafana**: View ztunnel metrics via Prometheus
- **Kubectl**: Inspect ztunnel pods and logs

### Logging

Ztunnel logs are captured by the cluster's logging collector (Alloy or Fluentbit) and shipped to your configured logging backend (Loki or Elasticsearch).

### Monitoring

Ztunnel exposes metrics on port `15020` at both `/metrics` and `/stats/prometheus` endpoints. When using Big Bang's monitoring stack, ztunnel metrics are **automatically scraped** by the existing `istio-envoy` PodMonitor because:

- Ztunnel's container is named `istio-proxy`
- Ztunnel includes the required Prometheus annotations (`prometheus.io/scrape: "true"`)

No additional configuration is required for metrics collection.

Key metrics exposed include:

| Metric | Description |
|--------|-------------|
| `istio_build` | Build info (component, version) |
| `istio_tcp_connections_opened_total` | TCP connections opened with source/destination labels |
| `istio_tcp_connections_closed_total` | TCP connections closed |
| `istio_tcp_received_bytes_total` | Bytes received per connection |
| `istio_tcp_sent_bytes_total` | Bytes sent per connection |
| `istio_xds_message_total` | XDS control plane messages |

Metrics include rich labels for traffic analysis: source/destination workload, namespace, service, app, version, and `connection_security_policy` (showing `mutual_tls` when mTLS is active).

### Health Checks

Standard Kubernetes readiness and liveness probes are configured for ztunnel pods.

### High Availability

Ztunnel runs as a DaemonSet, ensuring one instance per node. This architecture provides inherent high availability as traffic can be routed through any available ztunnel instance.

### Dependent Packages

Ztunnel requires the following packages:

- **istiod**: The Istio control plane that configures ztunnel
- **istio-cni**: Required for traffic interception in ambient mode

Optional but recommended:

- **Gateway API**: Provides the CRDs for configuring traffic routing in ambient mode
- **Kiali**: Visualization and management of the ambient mesh
- **Monitoring**: Metrics collection and dashboards

### Configuration

Values can be passed through to the ztunnel chart:

```yaml
ztunnel:
  enabled: true
  values:
    # Upstream chart values go here
    upstream:
      env:
        COLOR: red
```

### Ambient Mode

To enable full Istio ambient mode with ztunnel, configure Big Bang with:

```yaml
istio:
  ambient:
    enabled: true
```

This will automatically enable and configure istio-cni, Gateway API, and ztunnel with the appropriate settings.
