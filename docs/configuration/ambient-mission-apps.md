# Running Mission Applications in Big Bang with Istio Ambient Mode

[[_TOC_]]

## Overview

Big Bang enables Istio ambient mode for all integrated packages by setting `istio.ambient.enabled` to `true`. When enabled, Big Bang deploys the required ambient infrastructure and labels Big Bang-managed package namespaces with `istio.io/dataplane-mode: ambient`.

Mission applications and external Helm charts can still require additional work depending on how they are deployed and whether their chart has been integrated with [bb-common](../community/development/package-integration/bb-common.md). This document covers the expected paths for:

- A package deployed through the Big Bang `packages` key that has not been integrated with `bb-common`.
- A completely external Helm chart deployed outside of the Big Bang `packages` key.
- A mission application that must run in Istio sidecar mode while the rest of the environment uses ambient mode.

> [!IMPORTANT]
> Where possible, prefer integrating the chart with [bb-common](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/INTEGRATION_GUIDE.md). The common library keeps service mesh, network policy, and authorization policy behavior aligned with Big Bang defaults and reduces the number of hand-maintained manifests required by operators. It also provides additional functionality needed for a given package to work properly in ambient mode.

The examples in this document use the Parabol community package as a representative mission application. The same ambient mode concepts apply to other mission applications, but namespaces, ports, selectors, and package-specific Helm values must be adjusted for the application being deployed.

> [!NOTE]
> The additional resources described in this article are limited to what is needed for an application to work in ambient mode, or to work in sidecar mode when the rest of the environment is running in ambient mode. A given package may still need other network policies, authorization policies, or package-specific configuration to function fully; those requirements are outside the scope of this article.

## Before You Start

Confirm the ambient control plane is enabled:

```yaml
istio:
  ambient:
    enabled: true
```

Review the following existing documentation before choosing an integration path:

- [Configuring Istio Ambient Mode in Big Bang](./ambient.md)
- [Extra Package Deployment](../installation/environments/extra-package-deployment.md)
- [bb-common Integration](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/INTEGRATION_GUIDE.md)

## Additional Network Policies/Network Policy Changes

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

Since network policies behave differently in ambient mode, authorization policies are enabled by default and deny traffic that is not otherwise allowed. At a minimum, every application needs an authorization policy that allows traffic within its own namespace.

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
    matchLabels:
      <Update with Appropriate Pod Labels>
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
    matchLabels:
      <Update with Appropriate Pod Labels>
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

## Extra Package Deployment Using Packages Key

Use this path only when the chart cannot be modified to consume `bb-common`. Operators must explicitly provide the network policies and Istio resources that `bb-common` would normally help generate.

The following example shows how to deploy the Parabol community package in a test environment via the `packages` key:

```yaml
packages:
  parabol:
    enabled: true
    namespace:
      name: parabol
    helmRelease:
      namespace: "bigbang"
    sourceType: "git"
    git:
      repo: https://repo1.dso.mil/big-bang/product/community/parabol.git
      path: "./chart"
      branch: "main"
    values:
      global:
        imageRegistry:
          host: registry1.dso.mil
          imagePullSecrets:
            - name: private-registry
      networkPolicies:
        enabled: true
      services:
        redis:
          localStorage:
            enabled: true
        postgres:
          localStorage:
            enabled: true
            volumeSize: 10Gi
        parabol:
          localStorage:
            enabled: true
            storage: 1Gi
            awsEbs: false
            storageClassName: "local-path"
            accessModes:
            - ReadWriteOnce
      parabolDeployment:
        env:
          serverId: 1
          authGooleDisabled: false
        readinessProbe:
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
          successThreshold: 1
          httpGet:
            path: /manifest.json
            port: 3000
```

### Additional Policies

The following additional network policies and authorization policies were also needed to allow the application to function properly:

```yaml
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-kubelet-healthprobes
  namespace: parabol
spec:
  podSelector: {}
  ingress:
  - from:
    - ipBlock:
        cidr: 169.254.7.127/32
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-to-postgresql-metrics-from-prometheus
  namespace: parabol
spec:
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: monitoring
      podSelector:
        matchLabels:
          app.kubernetes.io/name: prometheus
    ports:
    - port: 9187
      protocol: TCP
    - port: 15008
      protocol: TCP
  podSelector:
    matchLabels:
      app.kubernetes.io/component: postgres
  policyTypes:
  - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-to-redis-metrics-from-prometheus
  namespace: parabol
spec:
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: monitoring
      podSelector:
        matchLabels:
          app.kubernetes.io/name: prometheus
    ports:
    - port: 9121
      protocol: TCP
    - port: 15008
      protocol: TCP
  podSelector:
    matchLabels:
      app.kubernetes.io/component: redis
  policyTypes:
  - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-from-public-ingressgateway
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

```yaml
---
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: default-authz-allow-all-in-ns
  namespace: parabol
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces:
        - parabol
---
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-ingress-to-postgresql-metrics-from-ns-monitoring-with-identity-monitoring-monitoring-kube-prometheus
  namespace: parabol
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
        - "9187"
  selector:
    matchLabels:
      app.kubernetes.io/component: postgres
---
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-ingress-to-redis-metrics-from-ns-monitoring-with-identity-monitoring-monitoring-kube-prometheus
  namespace: parabol
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
        - "9121"
  selector:
    matchLabels:
      app.kubernetes.io/component: redis
---
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: parabol-public-ingressgateway-authz-policy
  namespace: parabol
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
    matchLabels:
      app.kubernetes.io/name: parabol
      app.kubernetes.io/component: webserver
```

## External Helm Chart Deployment Using Argo CD in Ambient Mode

Mission applications deployed via Argo CD can also be configured to run in ambient mode by using the following steps:

1. Create the namespace in advance with the proper label:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: parabol
  labels:
    istio.io/dataplane-mode: "ambient"
```

2. Deploy the same authorization and network policies mentioned for the [previous scenario](ambient-mission-apps.md#additional-policies) along with any other package-specific policies.

3. Use the following YAML to deploy the application:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: parabol
spec:
  destination:
    namespace: parabol
    server: https://kubernetes.default.svc
  source:
    path: chart
    repoURL: https://repo1.dso.mil/big-bang/product/community/parabol.git
    targetRevision: 4.0.6
    helm:
      parameters:
        - name: global.imageRegistry.imagePullSecrets[0].name
          value: private-registry
        - name: services.parabol.localStorage.storageClassName
          value: local-path
        - name: services.parabol.localStorage.awsEbs
          value: 'false'
        - name: services.parabol.localStorage.accessModes[0]
          value: ReadWriteOnce
  project: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      enabled: true
```

## Sidecar Mode Mission Application Using Argo CD

The same process works when configuring the mission application to function in sidecar mode as well. The only difference is the label on the namespace that is created in advance:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: parabol
  labels:
    istio-injection: enabled
```

> [!NOTE]
> Configuring a mission application to operate in sidecar mode while Big Bang is in ambient mode should be considered a temporary solution as sidecar mode will be deprecated after Big Bang 4.0.