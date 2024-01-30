# Metric Server

## Overview

> Metric Server is an addon cluster utility that adds functionality to Kubernetes clusters rather than applications. It is used for monitoring pod CPU & memory utilization for use with autoscaling pods horizontally and vertically.

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

### Deployment

Since metrics server is prerequisite for a number of Kubernetes components (HPA, scheduler, kubectl top)
it typically will run by default in all Kubernetes clusters. Metrics server initiates connections to nodes,
due to security reasons (policy allows only connection in the opposite direction) so it has to run on user’s node.
 
There will be only one instance of metrics server running in each cluster.

## Big Bang Touch Points

### Architecture: 
- [Kubernetes Metrics Server](https://github.com/kubernetes-sigs/metrics-server?tab=readme-ov-file#kubernetes-metrics-server)
- [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
  - [How does Horizontal Pod Autoscaling Work?](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#how-does-a-horizontalpodautoscaler-work)

### Storage

To store data in memory Metric Server will replace the default storage layer (etcd) by introducing in-memory store which will implement [Storage interface](https://github.com/kubernetes/apiserver/blob/master/pkg/registry/rest/rest.go).

Only the most recent value of each metric will be remembered.

Users looking to access historical data should look into Prometheus and Grafana packages as part of Big Bang's [monitoring stack](https://repo1.dso.mil/big-bang/product/packages/monitoring).

### Istio Configuration

Istio is disabled in the metric server chart by default and can be enabled by setting the following values in the bigbang chart:

```yaml
istio:
  enabled: true
```

These values get passed into the metric server chart [here](https://repo1.dso.mil/big-bang/product/packages/metrics-server/-/blob/main/chart/values.yaml) or more specifically [here](https://repo1.dso.mil/big-bang/product/packages/metrics-server/-/blob/main/chart/values.yaml#L199).

### High Availability

Metrics Server is simply installed in high availability mode by setting the `replicas` value greater than `1`. The default configuration within BigBang is 2 replicas.

Additional Metric Server High Availability documentation [here](https://github.com/kubernetes-sigs/metrics-server/blob/master/README.md#high-availability).

## Requirements

[Metric Server Requirements](https://github.com/kubernetes-sigs/metrics-server/blob/master/README.md#requirements)

https://github.com/kubernetes-sigs/metrics-server/blob/master/README.md#high-availability

## Single Sign on (SSO)

None. This service doesn't have a web interface.

## Other Resources

- [Metric Server Design Proposal](https://github.com/kubernetes/design-proposals-archive/blob/main/instrumentation/metrics-server.md)

## Licensing

Metric Server utilizes an [Apache 2.0](https://github.com/kubernetes-sigs/metrics-server/blob/master/LICENSE) for it's code.