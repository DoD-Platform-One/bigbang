# Metrics Server

## Overview

> Metrics Server is an addon cluster utility that adds functionality to Kubernetes clusters rather than applications. It is used for monitoring pod CPU & memory utilization for use with autoscaling pods horizontally and vertically.

Metrics Server collects resource metrics from Kubelets and exposes them in Kubernetes apiserver through [Metrics API] for use by [Horizontal Pod Autoscaler] and [Vertical Pod Autoscaler]. Metrics API can also be accessed by `kubectl top`, making it easier to debug autoscaling pipelines.

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

- CPU/Memory based horizontal autoscaling (learn more about [Horizontal Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/))
- Automatically adjusting/suggesting resources needed by containers (learn more about [Vertical Autoscaling](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler/))

Don't use Metrics Server when you need:

- Non-Kubernetes clusters
- An accurate source of resource usage metrics
- Horizontal autoscaling based on other resources than CPU/Memory

For unsupported use cases, check out full monitoring solutions like Prometheus (also deployed by default within the BigBang [monitoring package](https://repo1.dso.mil/big-bang/product/packages/monitoring)).

### Deployment

Since Metrics Server is prerequisite for a number of Kubernetes components (HPA, scheduler, kubectl top)
it typically will run by default in most Kubernetes clusters. By default within a BigBang deployment, the enabled value is set to `auto`, which installs only if metrics API endpoint is not present.

## Big Bang Touch Points

### Architecture: 

Metrics Server collects resource metrics from Kubelets (the primary "node agent" that runs on each node) and exposes them in Kubernetes apiserver through [Metrics API](https://github.com/kubernetes/metrics) for use by [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) and [Vertical Pod Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler/). Metrics API can also be accessed by `kubectl top`, making it easier to debug autoscaling pipelines.

- [Kubernetes Metrics Server](https://github.com/kubernetes-sigs/metrics-server?tab=readme-ov-file#kubernetes-metrics-server)
- [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
  - [How does Horizontal Pod Autoscaling Work?](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#how-does-a-horizontalpodautoscaler-work)

### Storage

To store data in memory Metric Server will replace the default storage layer (etcd) by introducing in-memory store which will implement [Storage interface](https://github.com/kubernetes/apiserver/blob/master/pkg/registry/rest/rest.go).

Only the most recent value of each metric will be remembered.

Users looking to access historical data should look into Prometheus and Grafana packages as part of BigBang's [monitoring stack](https://repo1.dso.mil/big-bang/product/packages/monitoring).

### Istio Configuration

Istio is disabled in the metric server chart by default and can be enabled by setting the following values in the bigbang chart:

```yaml
istio:
  enabled: true
```

These values get passed into the metric server chart [here](https://repo1.dso.mil/big-bang/product/packages/metrics-server/-/blob/main/chart/values.yaml).

### High Availability

Metrics Server is simply installed in high availability mode by setting the `replicas` chart value greater than `1`. The default configuration within BigBang is a 2 replica deployment.

Additional Metric Server High Availability documentation can be found [here](https://github.com/kubernetes-sigs/metrics-server/blob/master/README.md#high-availability).

## Requirements

Metrics Server has specific requirements for cluster and network configuration. These requirements aren't the default for all cluster
distributions. Please ensure that your cluster distribution supports these requirements before using Metrics Server:

- The kube-apiserver must [enable an aggregation layer].
- Nodes must have Webhook [authentication and authorization] enabled.
- Kubelet certificate needs to be signed by cluster Certificate Authority (or disable certificate validation by passing `--kubelet-insecure-tls` to Metrics Server)
- Container runtime must implement a [container metrics RPCs] (or have [cAdvisor] support)
- Network should support following communication:
  - Control plane to Metrics Server. Control plane node needs to reach Metrics Server's pod IP and port 10250 (or node IP and custom port if `hostNetwork` is enabled). Read more about [control plane to node communication](https://kubernetes.io/docs/concepts/architecture/control-plane-node-communication/#control-plane-to-node).
  - Metrics Server to Kubelet on all nodes. Metrics server needs to reach node address and Kubelet port. Addresses and ports are configured in Kubelet and published as part of Node object. Addresses in `.status.addresses` and port in `.status.daemonEndpoints.kubeletEndpoint.port` field (default 10250). Metrics Server will pick first node address based on the list provided by `kubelet-preferred-address-types` command line flag (default `InternalIP,ExternalIP,Hostname` in manifests).

[reachable from kube-apiserver]: https://kubernetes.io/docs/concepts/architecture/master-node-communication/#master-to-cluster
[enable an aggregation layer]: https://kubernetes.io/docs/tasks/access-kubernetes-api/configure-aggregation-layer/
[authentication and authorization]: https://kubernetes.io/docs/reference/access-authn-authz/kubelet-authn-authz/
[container metrics RPCs]: https://github.com/kubernetes/community/blob/master/contributors/devel/sig-node/cri-container-stats.md
[cAdvisor]: https://github.com/google/cadvisor

Resource footprint on nodes within cluster are minimal at: 1 mili core of CPU and 2 MB of memory per node.

- [Metric Server Requirements](https://github.com/kubernetes-sigs/metrics-server/blob/master/README.md#requirements)

## Single Sign on (SSO)

None. This service doesn't have a web interface.

## Other Resources

- [Metric Server Design Proposal](https://github.com/kubernetes/design-proposals-archive/blob/main/instrumentation/metrics-server.md)

## Licensing

Metric Server utilizes an [Apache 2.0](https://github.com/kubernetes-sigs/metrics-server/blob/master/LICENSE)  license.