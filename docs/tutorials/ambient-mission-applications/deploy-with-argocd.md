# Deploy an Ambient Mission Application with Argo CD

[[_TOC_]]

This tutorial deploys Parabol as an external Helm chart managed by Argo CD while Big Bang uses Istio ambient mode. Adapt namespaces, versions, storage, ports, selectors, and policies for the application and target cluster.

## Before You Start

- Enable and verify Big Bang ambient mode.
- Install and configure Argo CD with access to the package repository and target cluster.
- Complete [Prepare a Mission Application for Istio Ambient Mode](prepare-application.md).
- Confirm the `argocd` namespace is the correct namespace for `Application` resources in the environment.

## Deploy the Application

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

2. Deploy the policies identified in the [shared ambient requirements](prepare-application.md) and adapt the [Parabol policy examples](deploy-with-packages-key.md#add-application-policies) for this deployment.

3. Use the following YAML to deploy the application:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: parabol
  namespace: argocd
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
          value: "false"
        - name: services.parabol.localStorage.accessModes[0]
          value: ReadWriteOnce
  project: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      enabled: true
```

Manage the Namespace, policies, and Argo CD `Application` declaratively in the environment's GitOps repository.

## Reconcile and Verify

After Argo CD reconciles the application, verify its status, workloads, policies, and ambient enrollment:

```shell
kubectl get application parabol -n argocd
kubectl wait --for=condition=Ready pod --all -n parabol --timeout=10m
kubectl get namespace parabol --show-labels
kubectl get networkpolicy,authorizationpolicy -n parabol
kubectl get service,endpointslice -n parabol
istioctl ztunnel-config workloads | grep parabol
```

Confirm that Argo CD reports the application as Synced and Healthy, all expected pods pass their probes, the namespace is labeled for ambient mode, and the workloads appear in ztunnel. Test the application's ingress route and confirm that Prometheus can scrape each enabled metrics endpoint.

## Clean Up

Remove the Argo CD `Application`, application policies, and Namespace from the GitOps repository, then allow Argo CD to reconcile. Review the chart's retention behavior and back up or retain required persistent volumes before enabling pruning.
