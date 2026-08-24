# Prepare a Mission Application for Istio Ambient Mode

[[_TOC_]]

This guide identifies the namespace, Kubernetes `NetworkPolicy`, and Istio `AuthorizationPolicy` requirements commonly needed before deploying a mission application into Big Bang's ambient mesh. Apply only the policies the application needs and replace every placeholder with values for the target workload.

## Before You Start

- Enable ambient mode as described in [Configuring Istio Ambient Mode in Big Bang](../../configuration/ambient.md).
- Identify the application's namespace, workload labels, service ports, metrics ports, ingress gateway, and required callers.
- Determine the kubelet or node source CIDRs used for health probes on the target platform.
- Prefer integrating the chart with [bb-common](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/INTEGRATION_GUIDE.md) when the chart can be modified.

## Network Policy Requirements

### Allowing HBONE Traffic

Once ambient mode is enabled, traffic is tunneled between workloads using TCP port 15008. As a result, this port is required for communication to continue as expected. Additionally, the original port should remain open to allow non-HBONE traffic to continue working.

Original:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-hbone-from-public-ingressgateway
  namespace: parabol
spec:
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: istio-gateway
          podSelector:
            matchLabels:
              app.kubernetes.io/name: public-ingressgateway
              istio: ingressgateway
      ports:
        - port: 3000
          protocol: TCP
  podSelector:
    matchLabels:
      app.kubernetes.io/name: parabol
      app.kubernetes.io/component: webserver
  policyTypes:
    - Ingress
```

Updated:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-hbone-from-public-ingressgateway
  namespace: parabol
spec:
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: istio-gateway
          podSelector:
            matchLabels:
              app.kubernetes.io/name: public-ingressgateway
              istio: ingressgateway
      ports:
        - port: 3000
          protocol: TCP
        - port: 15008
          protocol: TCP
  podSelector:
    matchLabels:
      app.kubernetes.io/name: parabol
      app.kubernetes.io/component: webserver
  policyTypes:
    - Ingress
```

> [!NOTE]
> If the application does not communicate outside its namespace and runs in sidecar mode, this is not needed.

### Allowing Kubelet Traffic

When a package is in ambient mode, it also requires an additional network policy to allow traffic from the kubelet so health and readiness probes continue functioning as expected.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ingress-allow-kubelet-healthprobes
spec:
  podSelector: {}
  ingress:
    - from:
        - ipBlock:
            cidr: 169.254.7.127/32
```

For more information about these network policies, please refer to [Istio's Ambient and Kubernetes Network Policy Documentation](https://istio.io/latest/docs/ambient/usage/networkpolicy/).

## Authorization Policies

Big Bang enables authorization policy generation by default for integrated packages. A chart that is not integrated with `bb-common` must provide equivalent policies itself. When an Istio `ALLOW` policy applies to a workload, requests that do not match an applicable `ALLOW` rule are denied. Most applications therefore need a policy that permits their required same-namespace traffic.

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: default-authz-allow-all-in-ns
  namespace: <Update with Package Namespace>
spec:
  action: ALLOW
  rules:
    - from:
        - source:
            namespaces:
              - <Update with Package Namespace>
```

It is also recommended to have an allow-nothing authorization policy as shown below:

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: default-authz-allow-nothing
  namespace: <Update with Package Namespace>
spec: {}
```

### Prometheus Ingress

Another common authorization policy allows Prometheus to scrape metrics endpoints via an application’s ServiceMonitor:

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-ingress-to-metrics-from-ns-monitoring-with-identity-monitoring-monitoring-kube-prometheus
  namespace: <Update with Package Namespace>
spec:
  action: ALLOW
  rules:
    - from:
        - source:
            principals:
              - cluster.local/ns/monitoring/sa/monitoring-monitoring-kube-prometheus
      to:
        - operation:
            ports:
              - <Update with Appropriate Port>
  selector:
    matchLabels: <Update with Appropriate Pod Labels>
```

### Istio Gateway Ingress

If the application allows traffic from an Istio ingress gateway, the following authorization policy may also be needed:

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-gateway-authz-policy
  namespace: <Update with Package Namespace>
spec:
  action: ALLOW
  rules:
    - from:
        - source:
            namespaces:
              - istio-gateway
            principals:
              - cluster.local/ns/istio-gateway/sa/public-ingressgateway-ingressgateway-service-account
  selector:
    matchLabels: <Update with Appropriate Pod Labels>
```

> [!NOTE]
> You may need to update the principal accordingly if using a non-default gateway.

## Namespace Labels

To label an application for ambient mode, use the following namespace label instead of the typical sidecar injection label:

```yaml
istio.io/dataplane-mode: ambient
```

> [!NOTE]
> This is handled automatically when using the `packages` key method.

## Verify the Ambient Prerequisites

After the namespace and policies reconcile, verify them before deploying or testing the application:

```shell
MISSION_NAMESPACE="replace-me"
kubectl get namespace "$MISSION_NAMESPACE" --show-labels
kubectl get networkpolicy -n "$MISSION_NAMESPACE"
kubectl get authorizationpolicy -n "$MISSION_NAMESPACE"
istioctl ztunnel-config workloads | grep "$MISSION_NAMESPACE"
```

Confirm that:

- The namespace has `istio.io/dataplane-mode=ambient`.
- The expected workload appears in the ztunnel workload list after it is deployed.
- Network policies allow both the application port and HBONE port `15008` where ambient traffic enters.
- Health probes, ingress traffic, and metrics callers match explicit policy rules.

Do not copy the example kubelet CIDR without confirming it for the target cluster.
