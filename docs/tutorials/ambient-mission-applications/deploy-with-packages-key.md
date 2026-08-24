# Deploy an Ambient Mission Application with the `packages` Key

[[_TOC_]]

This tutorial deploys the Parabol community package through Big Bang's `packages` key and supplies the policies needed for the example to operate in ambient mode. Adapt namespaces, versions, storage, ports, selectors, and policies for the application and target cluster.

## Before You Start

- Enable and verify Big Bang ambient mode.
- Complete [Prepare a Mission Application for Istio Ambient Mode](prepare-application.md).
- Review [Extra Package Deployment](../../installation/environments/extra-package-deployment.md).
- Use an immutable package tag and confirm that it is supported by the target Big Bang environment.

## Configure the Package

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
      tag: "4.0.6"
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

## Add Application Policies

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

Manage these policies through the same GitOps workflow as the environment configuration. Reconcile them with the package so a policy is not silently removed while the workload remains deployed.

## Reconcile and Verify

After committing the values and policies, reconcile the environment and verify the source, release, workload, and ambient enrollment:

```shell
flux get sources git -n bigbang
flux get helmreleases -n bigbang
kubectl wait --for=condition=Ready pod --all -n parabol --timeout=10m
kubectl get namespace parabol --show-labels
kubectl get networkpolicy,authorizationpolicy -n parabol
kubectl get service,endpointslice -n parabol
istioctl ztunnel-config workloads | grep parabol
```

Confirm that Flux reports the Parabol source and HelmRelease as Ready, all expected pods pass their probes, the namespace is labeled for ambient mode, and the workloads appear in ztunnel. Test the application's ingress route and confirm that Prometheus can scrape each enabled metrics endpoint.

## Clean Up

Set `packages.parabol.enabled` to `false` or remove the package from the environment values, remove the application-specific policies, and reconcile Big Bang. Before pruning, decide whether the Parabol, PostgreSQL, and Redis persistent volumes must be retained or backed up.
