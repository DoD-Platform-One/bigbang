# Extra Package Deployment

⚠️ **NOTE: This doc is a work in progress as this functionality is not standardized or fully tested yet. Changes may happen at any point, and this functionality should be considered as BETA until Big Bang 2.0.** ⚠️

When using Big Bang you often find that you need or want to deploy an additional package alongside your chosen core/addon packages. This might be a mission app or just an extra helm chart from the Big Bang community or broader helm/kubernetes community.

In order to ease the burden on end users and increase integration with Big Bang components we have provided a way to deploy these additional packages with extra "wrapping" to provide additional alignment with Big Bang standards.

## What is provided

When utilizing the extra package values/logic there are two main pieces that are deployed: your package and a wrapper. Each of these pieces provides certain things necessary for deploying.

### Package

By deploying your package with the Big Bang values you will get the below all through Big Bang values control:
- Flux `GitRepository` or `HelmRepository` depending on configuration
- Flux `HelmRelease` or `Kustomization` depending on configuration
- Control of flux settings for the above
- Control of `postRenderers` is using Flux `HelmRelease`
- Passthrough of values to configure your package chart

The alternative is that customers would need to manage these things in a "sideloaded" fashion and not have these tied to the Big Bang deployment lifecycle/management.

### Wrapper

The wrapper provides additional integrations with key Big Bang components and standards, as well as extensibility features for common use cases. All of these can be tailored to a given package's needs witha simple interface. Currently included are:
- Istio: injection/sidecars, `VirtualService` for ingress, and `PeerAuthentication` for mTLS
- Monitoring: `ServiceMonitor` for metrics, alerts for alertmanager, dashboards for Grafana
- NetworkPolicies: Default set of "best practice" network policies with opptions to extend
- Secret creation (of arbitrary content)
- Configmap creation (of arbitrary content)
- SSO configuration with Authservice (not fully automated, requires additional configuration of chains)

These pieces can typically be complicated to get setup correctly and connected to components that are provided in Big Bang core, so we provide a simplified interface to add them.

## How to use it

The first piece you need in order to make use of this extensibility is the addition of `wrapper` in your Big Bang values. As of this documentation revision that should look like the below:

```yaml
ociRepositories:
  - name: "registry1"
    repository: "oci://registry1.dso.mil/bigbang"
    existingSecret: "private-registry"

wrapper:
  oci:
    name: wrapper
    tag: "0.1.0"
    repo: "registry1"
```

In Big Bang 2.0 this will be included in the default values with an OCI source. The wrapper does not require any additional values (simply need to point to its "storage" location of git/helm repository as seen above).

The wrapper does not add anything additional to your deployment, unless you also specify a `packages` value which configures what package to deploy and what wrapper configuration is desired. A basic example of a package deployment could look like this:

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
NOTE: The wrapper is an opt-in feature.  Without enabling the wrapper, the `packages` will default to deploying flux object for your chart, without any wrapper-added configuration.

The package also has OCI support for sourcing the artifacts; usage will be encouraged with the move to 2.0 and "first-class" support for `HelmRepository` resources.

With these values added you should have a very basic deployment of `podinfo` added onto your Big Bang install with some basic default integrations. The rest of this guide will walk you through each section of Big Bang touchpoints and some example configurations you could use. Each of the configurations are compatible with each other (i.e. you can combine the examples below).

### Basic Overrides

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
    values:
      replicaCount: 3
```

In this example we are doing two things:
- Overriding the Flux timeout on our `HelmRelease` to be 5 minutes
- Passing a value directly to the Podinfo chart to create 3 replicas

We could also specify a `postRenderers` value here, which is documented well in [this document](../../understanding-bigbang/configuration/postrenderers.md).

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
