# Configuring an Egress Gateway (Ambient Mode)

> **Alpha:** this feature is in alpha. Values, generated resources, and
> package coverage may change between releases.

Big Bang can deploy a shared egress gateway that packages bind their outbound
routes to: an
[ambient waypoint](https://istio.io/latest/docs/ambient/usage/waypoint/) in
the `istio-egress` namespace, deployed via the
[istio-egress-gateway](https://repo1.dso.mil/big-bang/product/packages/istio-egress-gateway)
package. This document assumes Istio ambient mode is already enabled
(`istio.ambient.enabled: true`); the egress gateway requires it.

Using an egress gateway provides:

- **A single exit point for external traffic:** package egress flows through
  one place instead of every pod reaching the Internet directly.
- **Default-deny egress authorization:** the waypoint denies all traffic
  except what each route's AuthorizationPolicy allows, enforcing per-host,
  per-source policy on mTLS workload identity, outside the client pod.
- **A registry replacement:** ambient mode drops sidecar mode's
  `REGISTRY_ONLY` guardrail; the waypoint restores (stronger) control over
  which external hosts are reachable. See
  [Restrictive NetworkPolicies are still critical](#restrictive-networkpolicies-are-still-critical).
- **Centralized observability:** egress traffic is visible in one waypoint's
  Istio telemetry rather than scattered across namespaces.

## Enabling

Enable the egress gateway:

```yaml
istio:
  egressGateway:
    enabled: true
```

This flag enables:
- `istioEgressGateway` package which creates the default `egress-waypoint` and  `istio-egress` namespace
- default egress routing through the `egress-waypoint` for all outbound routes configured by integrated packages

### Complete example

Once the gateway is deployed, a package routes an external host through it by
declaring an outbound route in its bb-common values. For supported Big Bang
packages the umbrella configures the default `egressGateway` (see
[Default waypoint binding for packages](#default-waypoint-binding-for-packages)):

```yaml
routes:
  defaults:
    outbound:
      # configured by the umbrella for supported packages
      egressGateway: istio-egress/egress-waypoint
  outbound:
    external-host:
      enabled: true
      hosts:
        - external-host.com
      # ports default to HTTPS/443
```

From this route bb-common renders, in the package namespace: the ServiceEntry
(`external-host-external`) labeled with the `istio.io/use-waypoint` labels,
the AuthorizationPolicy (`external-host-external-egress`) targeting it and
admitting only this package's workloads, and a NetworkPolicy allowing HBONE
egress to the waypoint.

```mermaid
flowchart TB
    subgraph pkg["package namespace"]
        direction TB
        pod["workload pod<br>(ztunnel-captured)"]
        se["ServiceEntry<br>hosts: external-host.com<br>istio.io/use-waypoint labels"]
        ap["AuthorizationPolicy<br>(targets the ServiceEntry)"]
    end
    subgraph egress["istio-egress namespace"]
        direction TB
        wp["egress-waypoint pod<br>(created by istiod from the Gateway)"]
        deny["AuthorizationPolicy default-deny<br>(targets the Gateway)"]
    end
    pod -- "HBONE :15008" --> wp
    wp -- ":443" --> ext["external-host.com"]
    se -. binds route to .-> wp
    ap -. enforced at .-> wp
    deny -. enforced at .-> wp
```

The ServiceEntry's waypoint labels make ztunnel tunnel traffic for
`external-host.com` over HBONE to the waypoint pod instead of sending it
directly out; the waypoint evaluates the attached AuthorizationPolicies
against its default-deny baseline and forwards the allowed traffic to the
external host.

## Restrictive NetworkPolicies are still critical

The waypoint only governs traffic that reaches it. Even with the egress
gateway enabled, an overly permissive egress NetworkPolicy (an allow-anywhere
rule, or a broad `443 → 0.0.0.0/0`) leaves arbitrary external
hosts reachable: any rule wide enough to reach the Internet is a path around the waypoint, and
bypassed traffic never meets the default-deny baseline or the per-route
AuthorizationPolicies provided by the egress waypoint.

Nothing in the mesh backstops this: sidecar mode's `REGISTRY_ONLY`, which
refused to route traffic to undeclared hosts, has no ambient equivalent;
ztunnel passes unregistered destinations through untouched.

If your intent is to keep package egress scoped only to enumerated hosts
you must ensure external traffic has no path except HBONE (15008) to the waypoint.

## Configuring the default egress gateway

### Default waypoint binding for packages

`routes.defaults.outbound.egressGateway` is the `<namespace>/<name>` waypoint
reference the umbrella passes to packages; a package's outbound routes bind to
it unless a route sets its own `egressGateway`:

```yaml
routes:
  defaults:
    outbound:
      egressGateway: istio-egress/egress-waypoint
```

The default matches the default waypoint deployed by the istio-egress-gateway package, so it normally does not need to be
changed.

To override the Big Bang specified egress gateway set the binding explicitly
in the package's values, which win over the umbrella default:

```yaml
<package>:
  values:
    routes:
      defaults:
        outbound:
          egressGateway: istio-egress/egress-waypoint
```

Only set an explicit binding when the waypoint already exists: Istio fails
open, and a route bound to a missing waypoint egresses directly.

### Waypoint sizing and behavior

Chart values pass through `istioEgressGateway.values`. The waypoint Deployment
is generated by istiod, so sizing is expressed as strategic-merge patches under
`waypoint.config` (supported keys: `deployment`, `service`, `serviceAccount`,
`horizontalPodAutoscaler`, `podDisruptionBudget`; HPA and PDB are only created
when set). The chart delivers these via the Gateway's
`infrastructure.parametersRef`; the upstream mechanism is described under
[Automated deployment](https://istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment)
in Istio's Gateway API documentation. For example:

```yaml
istioEgressGateway:
  enabled: true
  values:
    waypoint:
      config:
        deployment:
          spec:
            replicas: 2
            template:
              spec:
                containers:
                  - name: istio-proxy
                    resources:
                      requests:
                        cpu: 500m
                        memory: 512Mi
                      limits:
                        cpu: 500m
                        memory: 512Mi
        podDisruptionBudget:
          spec:
            minAvailable: 1
```

The waypoint is shared by every bound route across all packages (a single
fate domain), so size it for the cluster's aggregate egress traffic.

Other chart values: `waypoint.name`, `waypoint.labels`/`annotations`,
`waypoint.listeners.port`, and `defaultDeny.enabled` (set `false` to drop the
default-deny baseline, leaving the waypoint open to any bound traffic). See the
[package documentation](https://repo1.dso.mil/big-bang/product/packages/istio-egress-gateway/-/blob/main/docs/overview.md)
for the full values reference.
