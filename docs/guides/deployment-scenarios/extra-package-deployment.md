# Extra Package Deployment

When using Big Bang you often find that you need or want to deploy an additional package alongside your chosen core/add-on packages. This might be a mission app or just an extra helm chart from the Big Bang community or broader helm/kubernetes community.

In order to ease the burden on end users and increase integration with Big Bang components, we have provided a way to deploy these additional packages with optional extra "wrapping" to provide integration with Big Bang capabilities.

Please open an issue in the [Big Bang repository](https://repo1.dso.mil/big-bang/bigbang/-/issues) or in the [Wrapper repository ](https://repo1.dso.mil/big-bang/product/packages/wrapper/-/issues) for any bugs you discover or for any new features or functionality you would like the package/wrapper to support.

## What is provided

When utilizing the extra package values/logic, there are two main pieces that are deployed: your package and optionally, the "wrapper." Each of these pieces provides certain things necessary for deploying. The standalone package functionality is recommended for charts that already have Big Bang integration (i.e., networkpolicies, monitoring support, and Istio support). Utilizing the optional wrapper method is recommended for non-integrated charts or mission applications.

## Package Deployment

By deploying your package with the Big Bang values, you will accomplish multiple things all through Big Bang values control. These accomplishments are listed in the following:

* Flux `GitRepository` or `HelmRepository,` depending on configuration.
* Flux `HelmRelease` or `Kustomization,` depending on configuration.
* Control of flux settings for the above.
* Control of `postRenderers` if using Flux `HelmRelease.`
* Passthrough of values to configure your package chart.

The alternative is that customers would need to manage these things in a "sideloaded" fashion and not have these tied to the Big Bang deployment lifecycle/management.

### Basic Overrides/Passthroughs

There are some basic override values provided to modify your Helm chart installation. These do NOT require the `wrapper.` An example of these values is included in the following:

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

In this example, we are doing three things:

* Overriding the Flux timeout on our `HelmRelease` to be five minutes.
* Adding a dependency on the `monitoring` HelmRelease in the `bigbang` namespace to ensure `podinfo` doesn't deploy until after `monitoring.`
* Passing a value directly to the Podinfo chart to create three replicas.

We could also specify a `postRenderers` value here, which is documented well in [this document](../../understanding-bigbang/configuration/postrenderers.md).

If you would like to have values for your extra package deployment adapt based on your Big Bang configuration, you could do something like what is listed in the following:

```yaml
packages:
  podinfo:
    values:
      istio:
        enabled: "{{ .Values.istio.enabled }}"
```

In this example, Istio will only be configured for podinfo if Istio is enabled for Big Bang.

#### Additional Scenarios

In some cases, you may want to deploy an additional package to a namespace that already exists which can be done by setting the `<package>.namespace.create` value to false as shown below:

```yaml
packages:
  istio-cni:
    namespace:
      create: false
      name: kube-system
    helmRelease:
      namespace: bigbang
    dependsOn:
      - name: istiod
        namespace: bigbang
    enabled: true
    sourceType: "git"
    git:
      repo: https://repo1.dso.mil/big-bang/apps/sandbox/istio-cni.git
      path: "./chart"
      tag: 1.27.0-bb.0
```

This deploys the istio-cni package with tag of `1.27.0-bb.0` to the kube-system namespace which already exists within the cluster.

It is also possible to disable the creation of the `imagePullSecret` by setting the `<package>.namespace.createRegistrySecret` to false:

```yaml
packages:
  istio-cni:
    namespace:
      create: false
      name: kube-system
    helmRelease:
      namespace: bigbang
    dependsOn:
      - name: istiod
        namespace: bigbang
    enabled: true
    sourceType: "git"
    git:
      repo: https://repo1.dso.mil/big-bang/apps/sandbox/istio-cni.git
      path: "./chart"
      tag: 1.27.0-bb.0
    values:
      upstream:
        # Enable ambient mode
        ambient:
          enabled: true
        global:
          platform: k3s
  ztunnel:
    namespace:
      create: false
      name: istio-system
      createRegistrySecret: false
    helmRelease:
      namespace: bigbang
    dependsOn:
      - name: istio-cni
        namespace: bigbang
    enabled: true
    sourceType: "git"
    git:
      repo: https://repo1.dso.mil/big-bang/apps/sandbox/ztunnel.git
      path: "./chart"
      branch: "main"
```

In this example, we are deploying the istio-cni package to the kube-system namepace where it will need to create the secret required to pull the image.  We are also deploying the ztunnel package which is reliant on the istio-cni package.  It deploys to another existing namespace (istio-system in this case) where that secret already exists so we have set the `createRegistrySecret` value to false to prevent duplication and errors.

Another available feature is to have the package automatically deploy a secret containing the SSO certificate authority based on the global key for `sso` in the umbrella template by setting the `<package>.sso.enabled` to true.

```yaml
packages:
  podinfo:
    sso:
      enabled: true
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
```

> **Note**: The above example is just to illustrate what it would look like to enable the sso behavior and is not a functional example.

> **Note**: The default behavior when leaving off these keys are to create the namepace, create the image pull secret in that namespace, and not to create the secret for sso in that namespace.

## Wrapper Deployment

The [Wrapper](https://repo1.dso.mil/big-bang/product/packages/wrapper) is a helm chart that provides additional integrations with key Big Bang components and standards, as well as extensibility features for common use cases. All of these can be tailored to a given package's needs with a simple interface. Currently included are those listed in the following:
* **Istio:** injection/sidecars, `VirtualService` for ingress, and `PeerAuthentication` for mTLS.
* **Monitoring:** `ServiceMonitor` for metrics, alerts for alertmanager, dashboards for Grafana.
* **NetworkPolicies:** Default set of "best practice" network policies with options to extend.
* **Secret creation** (of arbitrary content).
* **Configmap creation** (of arbitrary content).
* **SSO configuration with Authservice** (not fully automated, requires additional configuration of chains and labeling of workload to route to authservice).

These pieces can typically be complicated to get set up correctly and connected to components that are provided in Big Bang core; therefore, we provide a simplified interface to add them.

### How to Use the Wrapper

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

**NOTE:** The wrapper is an opt-in feature. Without enabling the wrapper, the `packages` will default to just deploying the pieces [mentioned above](#package-deployment).

The package also has HelmRepository support for sourcing the artifacts from a HelmRepo (of normal or OCI type). Usage of HelmRepos is encouraged if you have access to these types of artifacts.

With these values added, you should have a very basic deployment of `podinfo` added onto your Big Bang install with some basic default integrations. The rest of this guide will walk you through each section of Big Bang touchpoints and some example configurations you could use. Each of the configurations are compatible with each other (i.e., you can combine the examples that are provided in this document).

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

In this example, we are primarily adding a virtual service for ingress to our application (i.e., leveraging defaults to select the proper service). By using the wrapper we are also getting several default options including istio sidecar injection and STRICT mTLS.

There are more ways to modify the virtual service creation and mTLS config. Additional values can be referenced in the [wrapper chart istio section](https://repo1.dso.mil/big-bang/product/packages/wrapper/-/blob/6536759fef016db8b5504ad6c237f2daffe22844/chart/values.yaml#L31-75).

### Monitoring Configuration

The wrapper chart also provides ways to integrate with the monitoring stack (e.g., Prometheus, Alertmanager, and Grafana). A basic way to configure monitoring for `podinfo` is provided in the following:

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

In this example we are adding a service monitor that will target the port named `http.` We are leveraging a number of defaults here to select the proper service and metrics paths.

There are other ways to further modify monitoring settings including more advanced service monitor config. Additional values can be referenced in the [wrapper chart monitor section](https://repo1.dso.mil/big-bang/product/packages/wrapper/-/blob/6536759fef016db8b5504ad6c237f2daffe22844/chart/values.yaml#L77-91).

### Network Policy Configuration

The wrapper chart provides ways to configure network policies as needed for your application. A basic config for the `podinfo` application is provided in the following:

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

In this example, we are allowing the package to have egress to the Kubernetes control plane (i.e.,) API). This particular setting can be beneficial for operators that may need to create Kubernetes resources.

There are a number of additional configurations including allowing egress to https or more custom needs. Additional values can be referenced in the [wrapper chart network section](https://repo1.dso.mil/big-bang/product/packages/wrapper/-/blob/6536759fef016db8b5504ad6c237f2daffe22844/chart/values.yaml#L93-113).

### Configmap/Secret Creation

Often when deploying a Helm chart, you may be expected to point to an existing secret for credentials, a license, or external service configuration (i.e., S3/RDS). The values that can be helpful in creation of these items are provided in the following:

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

These secrets/configmaps are created prior to installation of your package; therefore, they can be referenced in any values you use to configure your package.
