# Istio

## Overview

[Istio](https://istio.io/latest/docs/concepts/what-is-istio/) is an open platform for providing a uniform way to [integrate microservices](https://istio.io/latest/docs/examples/microservices-istio/), manage [traffic flow](https://istio.io/latest/docs/concepts/traffic-management/) across microservices, enforce policies and aggregate telemetry data. Istio's control plane provides an abstraction
layer over the underlying cluster management platform, such as Kubernetes.

```mermaid
graph LR
  subgraph "Istio"
    dataplane("Data Plane<br/>AKA Gateway") 
    controlplane{{"Control Plane"}} --> dataplane
    igw("Ingress Gateway") --"http 8080<br/>https 8443<br/>istiod 15012<br/>status 15021<br/>tls 15443"--> dataplane
  end      

  ig("Ingress") --> igw

  subgraph "Monitoring"
    svcmonitor("Service Monitor") --> controlplane
    Prometheus --> svcmonitor("Service Monitor")
  end
  
  subgraph "App"
    dataplane --"app.bigbang.dev"<br/>port redirects--> appvs{{"Virtual Service"}} --> appsvc{{"App Service"}}
  end

  subgraph "Logging"
    controlplane --> fluent(Fluentbit) --> logging-ek-es-http
    logging-ek-es-http{{Elastic Service<br />logging-ek-es-http}} --> elastic[(Elastic Storage)]
  end
```

## Big Bang Touchpoints

### Licensing

Istio is an open source tool that utilizes an Apache-2.0 License.

### Storage

Aside from the packages that it can integrate with, Istio provides no storage requirements.

### High Availability

By default, Istio is configured with 1 istiod replica, but it can be configured in the Big Bang values to use horizontal pod autoscaling:

```yaml
istiod:
  values:
    upstream:
      replicaCount: 1
      hpaSpec:
        minReplicas: 1
        maxReplicas: 3
```

Likewise, the ingress gateway replicas can be specified and extra ingress gateways can be configured:

```yaml
istioGateway:
  values:
    upstream:
      minReplicas: 1
      maxReplicas: 5
    extraIngressGateways:
    # ...
```

### UI

Big Bang can be configured to deploy [Kiali](https://repo1.dso.mil/big-bang/product/packages/kiali) (a management console that provides dashboards, observability, and other robust capabilities) and [Tempo](https://repo1.dso.mil/big-bang/product/packages/tempo) (a distributed tracing backend), which can help you visualize your Istio mesh. To enable Kialia and Tempo, simply update the Big Bang values.yaml:

```yaml
istioCRDs:
  enabled: true
istiod:
  enabled: true
istioGateway:
  enabled: true
tempo:
  enabled: true
kiali:
  enabled: true
monitoring:
  enabled: true
```

### Logging

Within Big Bang, logs are captured by fluentbit and shipped to elastic by default.

### Monitoring

Monitoring can be enabled to automatically capture metrics for Istio when `monitoring.enabled` is set to `true` in the Big Bang values.yaml. Since Istio 1.5, standard metrics are directly exported by the Envoy proxy. For a list of metrics, see [Istio Standard Metrics](https://istio.io/latest/docs/reference/config/metrics/#metrics) and [Istio Observability](https://istio.io/latest/docs/ops/best-practices/observability/).

> **Note**: When using Kiali as a UI component of Istio, monitoring must be enabled as Kiali will not function properly without Prometheus.

Grafana (part of the monitoring packages) is a standalone component of Big Bang that can provide dashboards to show monitoring data. For more information, see Big Bang's [Grafana docs](https://repo1.dso.mil/big-bang/product/packages/monitoring/-/tree/main/docs#grafana) and [Visualizing Metrics with Grafana](https://istio.io/latest/docs/tasks/observability/metrics/using-istio-dashboard/).

### Healthchecks

There are standard readiness probes built into the envoy sidecars and istio containers. See [here](https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/#ReadinessProbe) for more info.

### Dependent Packages

- istio-crds
- istiod
- istio-cni (Optional for sidecar mode; Required for ambient mode)
- istio-gateway