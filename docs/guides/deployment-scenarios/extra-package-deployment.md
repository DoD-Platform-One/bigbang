# Extra Package Deployment

When using Big Bang you often find that you need or want to deploy an additional package alongside your chosen core/addon packages. This might be a mission app or just an extra helm chart from the Big Bang community or broader helm/kubernetes community.

In order to ease the burden on end users and increase integration with Big Bang components we have provided a way to deploy these additional packages with optional extra "wrapping" to provide integration with Big Bang capabilities.

Please open an issue in the [Big Bang repository](https://repo1.dso.mil/big-bang/bigbang/-/issues) or in the [Wrapper repository ](https://repo1.dso.mil/big-bang/product/packages/wrapper/-/issues) for any bugs you discover or for any new features or functionality you would like the package/wrapper to support.

## What is provided

When utilizing the extra package values/logic there are two main pieces that are deployed: your package and optionally the "wrapper". Each of these pieces provides certain things necessary for deploying. The standalone package functionality is recommended for charts that already have Big Bang integration (i.e. networkpolicies, monitoring support, istio support). Utilizing the optional wrapper method is recommended for non-integrated charts or mission applications.

## Package Deployment

By deploying your package with the Big Bang values you will get the below all through Big Bang values control:
- Flux `GitRepository` or `HelmRepository` depending on configuration
- Flux `HelmRelease` or `Kustomization` depending on configuration
- Control of flux settings for the above
- Control of `postRenderers` if using Flux `HelmRelease`
- Passthrough of values to configure your package chart

The alternative is that customers would need to manage these things in a "sideloaded" fashion and not have these tied to the Big Bang deployment lifecycle/management.

### Basic Overrides/Passthroughs

There are some basic override values provided to modify your Helm chart installation. These do NOT require the `wrapper`. An example of these values is included below:

```yaml
packages:
  podinfo:
    git:
      repo: https://github.com/stefanprodan/podinfo.git
      tag: 6.3.4
      path: charts/podinfo
    flux:
      timeout: 5m
    postRenderers: []
    dependsOn:
      - name: monitoring
        namespace: bigbang
    values:
      replicaCount: 3
```

In this example we are doing three things:
- Overriding the Flux timeout on our `HelmRelease` to be 5 minutes
- Adding a dependency on the `monitoring` HelmRelease in the `bigbang` namespace, to ensure `podinfo` doesn't deploy until after `monitoring`
- Passing a value directly to the Podinfo chart to create 3 replicas

We could also specify a `postRenderers` value here, which is documented well in [this document](../../understanding-bigbang/configuration/postrenderers.md).

If you would like to have values for your extra package deployment adapt based on your Big Bang configuration you could do something like the below:

```yaml
packages:
  podinfo:
    values:
      istio:
        enabled: "{{ .Values.istio.enabled }}"
```

In this example, Istio will only be configured for podinfo if Istio is enabled for BigBang.

## Wrapper Deployment

The [Wrapper](https://repo1.dso.mil/big-bang/product/packages/wrapper) is a helm chart that  provides additional integrations with key Big Bang components and standards, as well as extensibility features for common use cases. All of these can be tailored to a given package's needs with a simple interface. Currently included are:
- Istio: injection/sidecars, `VirtualService` for ingress, and `PeerAuthentication` for mTLS
- Monitoring: `ServiceMonitor` for metrics, alerts for alertmanager, dashboards for Grafana
- NetworkPolicies: Default set of "best practice" network policies with options to extend
- Secret creation (of arbitrary content)
- Configmap creation (of arbitrary content)
- SSO configuration with Authservice (not fully automated, requires additional configuration of chains and labeling of workload to route to authservice)

These pieces can typically be complicated to get setup correctly and connected to components that are provided in Big Bang core, so we provide a simplified interface to add them.

### How to use it

```yaml
packages:
  podinfo:
    enabled: true
    wrapper:
      enabled: true
    git:
      repo: https://github.com/stefanprodan/podinfo.git
      tag: 6.3.4
      path: charts/podinfo
```

NOTE: The wrapper is an opt-in feature.  Without enabling the wrapper, the `packages` will default to just deploying the pieces [mentioned above](#package-deployment).

The package also has HelmRepository support for sourcing the artifacts from a HelmRepo (of normal or OCI type); usage of HelmRepos is encouraged if you have access to these types of articats.

With these values added you should have a very basic deployment of `podinfo` added onto your Big Bang install with some basic default integrations. The rest of this guide will walk you through each section of Big Bang touchpoints and some example configurations you could use. Each of the configurations are compatible with each other (i.e. you can combine the examples below).

### Istio Configuration

The wrapper chart provides a number of different ways to provide Istio configuration. The below is a basic example configuring some pieces for the `podinfo` application:

```yaml
packages:
  podinfo:
    git:
      repo: https://github.com/stefanprodan/podinfo.git
      tag: 6.3.4
      path: charts/podinfo
    wrapper:
      enabled: true
    istio:
      hosts:
        - names:
            - podinfo
          gateways:
            - public
          destination:
            port: 9898
```

In this example we are primarily adding a virtual service for ingress to our application (leveraging defaults to select the proper service). By using the wrapper we are also getting several default options including istio sidecar injection and STRICT mTLS.

There are more ways to modify the virtual service creation and mTLS config; additional values can be referenced in the [wrapper chart istio section](https://repo1.dso.mil/big-bang/product/packages/wrapper/-/blob/6536759fef016db8b5504ad6c237f2daffe22844/chart/values.yaml#L31-75).

### Monitoring Configuration

The wrapper chart also provides ways to integrate with the monitoring stack (Prometheus, Alertmanager, and Grafana). The example below is a basic way to configure monitoring for `podinfo`:

```yaml
packages:
  podinfo:
    git:
      repo: https://github.com/stefanprodan/podinfo.git
      tag: 6.3.4
      path: charts/podinfo
    wrapper:
      enabled: true
    monitor:
      services:
        - spec:
            endpoints:
              - port: http
```

In this example we are adding a service monitor that will target the port named `http`. We are leveraging a number of defaults here to select the proper service and metrics paths.

There are other ways to further modify monitoring settings including more advanced service monitor config; additional values can be referenced in the [wrapper chart monitor section](https://repo1.dso.mil/big-bang/product/packages/wrapper/-/blob/6536759fef016db8b5504ad6c237f2daffe22844/chart/values.yaml#L77-91).

### Network Policy Configuration

The wrapper chart provides ways to configure network policies as needed for your application. The example below again provides a basic config for the `podinfo` application:

```yaml
packages:
  podinfo:
    git:
      repo: https://github.com/stefanprodan/podinfo.git
      tag: 6.3.4
      path: charts/podinfo
    wrapper:
      enabled: true
    network:
      allowControlPlaneEgress: true
      additionalPolicies: []
      # example of additional egress network policy
      # - name: egress-additional
      #   spec: 
      #     podSelector: {}
      #     policyTypes:
      #     - Egress
      #     egress:
      #     - to:
      #       ports:
      #       - protocol:
      #         port: 9999
```

In this example we are allowing the package to have egress to the Kubernetes control plane (aka API). This particular setting can be beneficial for operators that may need to create Kubernetes resources.

There are a number of additional configurations including allowing egress to https or more custom needs; additional values can be referenced in the [wrapper chart network section](https://repo1.dso.mil/big-bang/product/packages/wrapper/-/blob/6536759fef016db8b5504ad6c237f2daffe22844/chart/values.yaml#L93-113).

### Configmap / Secret Creation

Oftentimes when deploying a Helm chart you may be expected to point to an existing secret for credentials, a license, or external service configuration (S3/RDS). The below values can be helpful in creation of these items:

```yaml
packages:
  podinfo:
    git:
      repo: https://github.com/stefanprodan/podinfo.git
      tag: 6.3.4
      path: charts/podinfo
    wrapper:
      enabled: true
    configMaps:
      - name: config
        data:
          foo: bar
    secrets:
      - name: secret
        data:
          foo: YmFyCg==
```

These secrets/configmaps are created prior to installation of your package, so that they can be referenced in any values you use to configure your package.
