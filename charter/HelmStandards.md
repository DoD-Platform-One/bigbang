# Helm Package Standards

This document describes the technical standards that should be in place when building a Helm chart and integrating it with BigBang

## Helm Package Versioning Scheme

Big Bang packages follow a standard semantic versioning scheme for both the package tag and the chart version.  The package tag will always be in line with the chart version (not the `appVersion`).  To distinguish between BigBang specific changes within the semantic version of the upstream chart, a suffix of `-bb.#` will be added to _all_ charts and tags.

For example, for the upstream [`istio-operator`](https://github.com/istio/istio/tree/1.7.3/manifests/charts/istio-operator) pinned at version `1.7.3`, the big bang version (with the modified `values.yaml` for an Iron Bank image) will be tagged `1.7.3-bb.0`.  If in the same `istio-operator` release, BigBang requires chart modifications (such as to support `imagePullSecrets`), then the new version becomes `1.7.3-bb.1`.

For another example in using the [`kube-prometheus-stack`](https://github.com/prometheus-community/helm-charts/tree/kube-prometheus-stack-12.2.2/charts/kube-prometheus-stack), the upstream is versioned at `12.2.2`, meaning BigBang's initial fork will be `12.2.2-bb.0`.  Future additions, such as adding `VirtualServices` for the ingresses, bumps to the `-bb.#` will happen in sequence every time BigBang updates the chart within the same version.


## Big Bang Values File

* In the values.yaml file [here](../chart/values.yaml), each package should have its own region at `.package_name` if its in Core or `.addons.package_name`.
* User Interface:
  * If there exists need for ingress traffic into the package, the package should create a VirtualService conditional on the existance of `istio.enabled` being set to true.  This value should default to false.  The BigBang chart should set this true for all packages
  * There should be a region under the package for configuring SSO that looks like this when there are multiple packages
    ```yaml
      sso:
        enabled: false
        kiali:
            client_id: kiali
            client_secret: "change_me"
        jaeger:
            client_id: jaeger
            client_secret: "change_me"
    ```
    or like this if there is a single user interface:
    ```yaml
      sso:
        enabled: false
        client_id: twistlock_id
        client_secret: "change_me"
    ```
   * If sso is enabled and a value is not provided in the SSO configuration of the package, it should default to the top level SSO configuration
* Database Connections:
    * The BigBang chart should prevent the use of a database bundled as part of the package chart by default, and warn if an end user uses one anyways.
    * There should be a database section under the package configuration that matches the following section
    ```yaml
    database:
      # Entering connection info will enable external database and will auto-create any required secrets.
      host: ""
      port: ""
      username: ""
      password: ""
      database: ""
      type: "" # Optional. One of mysql, mssql, postgres, mongo if ther
    ```
* Monitoring
    * Charts should expect a value `monitoring.enabled` to be set by the BigBang chart to conditionally create monitoring components (`ServiceMonitors`, `PodMonitors`, etc).  This value should default to false


## Secrets

* The BigBang chart should make an `ImagePullSecret` in the namespace the package will be deployed in.
* If the package chart cannot accept credentials (e.g. for databses) as a value, then the BigBang chart should make the secret with values passed into BigBang and pass the Secret to the package chart by name.  

## Big Bang Helm Release

* The `ImagePullSecret` name as `private-registry` should be configured in each package's `chart/template/{package}/values.yaml` to be passed in to each Package.

## Common Values

* Every object in a package should have the following labels:

| Key | Description | Example |
| ------| -------| ------|
| app.kubernetes.io/name | The name of the application  | `argocd` |
| app.kubernetes.io/instance | The unique name identifying the instance of an application. Name of the `HelmRelease` | `argocd`
| app.kubernetes.io/version | The chart version that manages the object | `1.0.1-bb.10`
| app.kubernetes.io/component | the component within the architecture | `database` |

Each package shall have the ability to add labels to all objects via a top level `commonLabels` map.  The labels that will be passed in from
the Big Bang chart shall include at least:

| Key | Description | Example |
| ------| -------| ------|
| app.kubernetes.io/part-of | the name of a higher level application this one is part of | `bigbang` |
| app.kubernetes.io/managed-by | the tool being used to manage the operation of an application | `flux` |
| app.kubernetes.io/bigbang-version | The version of bigbang deployed | `1.0.7` |

which would be passed in via:

```yaml
commonLabels:
  app.kubernetes.io/part-of: bigbang
  app.kubernetes.io/managed-by: flux
  app.kubernetes.io/bigbang-version: 1.6.0
```

## Kubernetes Objects


These requirements for the kubernetes components come from the Kubernetes STIG, Kubesec.io and other best practices

* Resource Limits and Requests set for cpu and memory and they are [Guaranteed QoS](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/#create-a-pod-that-gets-assigned-a-qos-class-of-guaranteed)
* Containers are not run in privileged mode
* Read Only Root File System is set to true
* Containers are not run as root
* runAsUser >= 1000
* Each deployment/daemonset/statefulset should use its own service account with least privilege permission set
* HostPath volumes are not allowed
* All resources contain the [Kubernetes Common Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/)
* All containers contain health and liveness checks
