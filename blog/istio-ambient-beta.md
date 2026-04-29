# Ambient Mode on Big Bang is now in Beta

Big Bang 3.23 introduces support for **Istio Ambient Mesh** as an opt-in (beta) feature. With BB 3.23, Ambient Mode defaults to **disabled**, allowing existing deployments to continue operating using the existing sidecar pattern without disruption. Users can explicitly enable Ambient Mode to begin evaluating its benefits and tradeoffs in controlled environments.

This post provides a high-level overview of the Ambient Mesh capability, how this capability impacts cluster networking traffic, and the changes that were made in the Big Bang product to support it.

## Why Ambient?

Ambient Mesh offers major advantages over the sidecar model by reducing resource overhead. Instead of running a dedicated proxy in every Kubernetes pod, Ambient uses a shared Layer 4 proxy, ztunnel, on each Kubernetes cluster node. As workload count grows, this model becomes more efficient because proxy overhead no longer scales with every pod.

Ambient Mode also simplifies operations. Since applications are no longer tied to an injected sidecar, pods do not need to be restarted just to pick up Istio proxy updates.
Additionally, the Ambient Mesh architecture significantly reduces the complexity of onboarding and integrating mission applications into the Big Bang service mesh.

## Opt-In Ambient (Beta)

Ambient Mesh is available in Big Bang 3.23, but is not enabled by default. When enabled, it should be treated as a beta feature, and production use should be carefully evaluated based on your environment's needs. Ambient Mesh will ship as the default mesh networking configuration with BB 4.0.

Ambient can be enabled by setting the `istio.ambient.enabled` flag to `true` in your values configuration file, which enables it globally for all Big Bang applications.

For more information on configuration and what is enabled behind the scenes, refer to the [Enabling Ambient Mode documentation](https://docs-bigbang.dso.mil/latest/docs/configuration/ambient/#enabling-ambient-mode).

## Changes to the Network Stack

Ambient introduces a fundamental change in how traffic flows:

* **No per-pod sidecar proxies** → reduced resource overhead
* **Node-level L4 processing (ztunnel)** → handles mTLS and basic policy enforcement
* **Optional L7 processing (waypoints)** → used selectively for advanced use cases

One of the most significant changes from a networking perspective is that workloads now communicate over TCP port 15008 (HBONE) when using the tunnel. This requirement is automatically handled by the bb-common integration, which allows this port when Ambient is enabled.

From a security perspective, allowing HBONE tunnel traffic enables connectivity to destination workloads, so NetworkPolicy and AuthorizationPolicy must be configured to preserve intended segmentation. To address this, Big Bang automatically enables Layer 4 Authorization Policies to ensure environments remain properly segmented and secure.

For a deeper dive into the architecture, please check out [Istio Ambient Architecture](https://istio.io/latest/docs/ambient/architecture/).

## Current Implementation

Ambient Mesh is primarily a Layer 4-first architecture. Instead of injecting an Envoy sidecar into every workload, Istio uses ztunnel, a node-level proxy, to create a secure L4 overlay for meshed traffic. When teams need Layer 7 features—such as HTTP routing, header-based policy, or richer request-level telemetry—they can opt specific workloads into waypoint proxies. This split lets Ambient Mesh provide a lower-friction security baseline by default, while making deeper application-aware processing an explicit, targeted choice rather than a universal sidecar tax.

In Big Bang, this is particularly relevant for applications that rely on **Authservice** for authentication which are expected to continue to function in the same way (using the Authservice label), but should still be validated:

* Prometheus
* AlertManager
* Thanos

Additional waypoint proxies can be manually deployed using [Istio's configuration documentation](https://istio.io/latest/docs/ambient/usage/waypoint/), but there is currently no built-in support for templating them via the Big Bang chart.

## Troubleshooting Istio Ambient Mesh Workloads

Since the `istio-proxy` containers no longer exist, troubleshooting shifts to inspecting ztunnel logs.

The following command retrieves the last 500 log entries for all ztunnel pods:

`kubectl logs -l app.kubernetes.io/name=ztunnel -n istio-system --tail 500`

You can combine this with `grep` to filter for specific workloads or errors.

Below is an example of an error that indicates a problem with a missing or misconfigured network policy:

```
error	access	connection complete	src.addr=10.42.1.22:36146 src.workload="kiali-5f4f9bd98c-jdb59" src.namespace="kiali" src.identity="spiffe://cluster.local/ns/kiali/sa/kiali-service-account" dst.addr=10.42.1.17:15008 dst.hbone_addr=10.42.1.17:9090 dst.service="monitoring-monitoring-kube-prometheus.monitoring.svc.cluster.local" dst.workload="prometheus-monitoring-monitoring-kube-prometheus-0" dst.namespace="monitoring" dst.identity="spiffe://cluster.local/ns/monitoring/sa/monitoring-monitoring-kube-prometheus" direction="outbound" bytes_sent=0 bytes_recv=0 duration="0ms" error="io error: Connection refused (os error 111)"
```

> **Note**: As mentioned earlier, TCP port 15008 is the primary port used when in Ambient Mode so close attention should be paid to the `dst.addr` when troubleshooting network policy related issues. 

Another example shows what it may look like if you have a missing or misconfigured authorization policy:

```
error	access	connection complete	src.addr=10.42.1.22:56558 src.workload="kiali-5f4f9bd98c-jdb59" src.namespace="kiali" src.identity="spiffe://cluster.local/ns/kiali/sa/kiali-service-account" dst.addr=10.42.2.10:15008 dst.hbone_addr=10.42.2.10:3200 dst.service="tempo-tempo.tempo.svc.cluster.local" dst.workload="tempo-tempo-0" dst.namespace="tempo" dst.identity="spiffe://cluster.local/ns/tempo/sa/tempo-tempo" direction="inbound" bytes_sent=0 bytes_recv=0 duration="0ms" error="connection closed due to policy rejection: allow policies exist, but none allowed"
```

You can also use the [istioctl](https://istio.io/latest/docs/ops/diagnostic-tools/istioctl/) utility to analyze the entire environment to look for any issues that stick out by executing the following command:

`istioctl analyze -A`

For a more in-depth troubleshooting resource please refer to [Troubleshooting Istio Ambient](https://github.com/istio/istio/wiki/Troubleshooting-Istio-Ambient).

## Summary

Big Bang 3.23 introduces Ambient Mesh as a **beta, opt-in feature** that:

* **Simplifies the data plane** by removing per-pod proxies
* Shifts enforcement toward **L4 Authorization Policies + Network Policies**
* Supports **selective L7 processing** for authentication for packages that leverage Authservice

Please stay tuned for further updates and timeline on BB 4.0 as our Ambient implementation progresses.