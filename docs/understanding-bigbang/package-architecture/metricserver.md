# Metric Server

## Overview

> Metric Server is an addon cluster utility that adds functionality to Kubernetes clusters rather than applications. It is used for monitoring pod CPU & memory utilization.

Metrics Server collects resource metrics from Kubelets and exposes them in Kubernetes apiserver through [Metrics API]
for use by [Horizontal Pod Autoscaler] and [Vertical Pod Autoscaler]. Metrics API can also be accessed by `kubectl top`,
making it easier to debug autoscaling pipelines.

Metrics Server is not meant for non-autoscaling purposes. For example, don't use it to forward metrics to monitoring solutions, or as a source of monitoring solution metrics. In such cases please collect metrics from Kubelet `/metrics/resource` endpoint directly.

Metrics Server offers:

- A single deployment that works on most clusters (see [Requirements](#requirements))
- Fast autoscaling, collecting metrics every 15 seconds.
- Resource efficiency, using 1 mili core of CPU and 2 MB of memory for each node in a cluster.
- Scalable support up to 5,000 node clusters.

[Metrics API]: https://github.com/kubernetes/metrics
[Horizontal Pod Autoscaler]: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
[Vertical Pod Autoscaler]: https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler/

## Use cases

You can use Metrics Server for:

- CPU/Memory based horizontal autoscaling (learn more about [Horizontal Autoscaling])
- Automatically adjusting/suggesting resources needed by containers (learn more about [Vertical Autoscaling])

Don't use Metrics Server when you need:

- Non-Kubernetes clusters
- An accurate source of resource usage metrics
- Horizontal autoscaling based on other resources than CPU/Memory

For unsupported use cases, check out full monitoring solutions like Prometheus.

### Architecture:

- [Promtail Client](https://grafana.com/docs/loki/latest/clients/promtail/)

### Storage

Promtail does not persist data, and instead reads log files and streams the data to a log aggregation system.

### Istio Configuration

Istio is disabled in the promtail chart by default and can be enabled by setting the following values in the bigbang chart:

```yaml
istio:
  enabled: true
```

These values get passed into the promtail chart [here](https://repo1.dso.mil/big-bang/product/packages/promtail/-/blob/main/chart/values.yaml#L428).

## High Availability

Metrics Server is simply installed in high availability mode by setting the `replicas` value greater than `1`. The default configuration within BigBang is 2 replicas.

Additional Metric Server High Availability documentation [here](https://github.com/kubernetes-sigs/metrics-server/blob/master/README.md#high-availability).

## Requirements

[Metric Server Requirements](https://github.com/kubernetes-sigs/metrics-server/blob/master/README.md#requirements)

https://github.com/kubernetes-sigs/metrics-server/blob/master/README.md#high-availability

## Single Sign on (SSO)

None. This service doesn't have a web interface.

## Licensing

Promtail utilizes an [AGPLv3 License](https://github.com/grafana/loki/blob/main/LICENSE) for it's code and binaries.