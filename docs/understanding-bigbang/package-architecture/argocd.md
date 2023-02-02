# Argocd

## Overview

Argo CD is a declarative, [GitOps](https://www.gitops.tech/) continuous delivery tool for Kubernetes.

ArgoCD is a kubernetes native tool that enables the delivery of GitOps practices.  It uses a git repository as a source of truth in defining the desired state.  It is implemented as a kubernetes controller continuously monitoring running applications and reconciling it against the desired state in the source git repository.


Argo CD uses an Application Controller component to continuously watch applications that are executing.  Argo CD then differentiates the applications live state against the target state that resides in the Git repository. It supports a range of configuration management tools such as [Helm](https://helm.sh/), [kustomize](https://kustomize.io/), [ksonnet](https://ksonnet.io/get-started/), and [jsonnet](https://jsonnet.org/).

### Argocd

```mermaid
graph LR
  subgraph "ArgoCD"
    argocdservice1("argocd")
  end

  subgraph "Kubernetes Cluster 1"
    argocdservice1("argocd") --> k8scluster1("K8s Cluster 1")
  end

  subgraph "Kubernetes Cluster 2"
    argocdservice1("argocd") --> k8scluster2("K8s Cluster 2")
  end

  subgraph "Logging"
    argocdservice1("argocd") --> fluent(Fluentbit) --> logging-ek-es-http
    logging-ek-es-http{{Elastic Service<br />logging-ek-es-http}} --> elastic[(Elastic Storage)]
  end

  subgraph "Monitoring"
    svcmonitor("Service Monitor") --> argocdservice1("argocd")
    Prometheus --> svcmonitor("Service Monitor")
  end
```

For more information on the Argocd architecture, see [Argocd Architectural Overview](https://argo-cd.readthedocs.io/en/stable/operator-manual/architecture/).

## Big Bang Touch Points

### Licensing

The Big Bang Argocd deployment uses a permissive license (i.e., a free-software license which instead of copyleft protections, carries only minimal restrictions on how the software can be used, modified, and redistributed.) whose main conditions require preservation of copyright and license notices. Contributors provide an express grant of patent rights. Licensed works, modifications, and larger works may be distributed under different terms and without source code.

### Single Sign On

ArgoCD an be configured to support user login to the UI using identities from external identity providers that support SAML 2.0.

See below for an example of the values to provide to argocd for SSO setup:

```yaml
addons:
  argocd:
    sso:
      enabled: true
      client_id:
      client_secret: ""
      groups: |
        g, Impact Level 2 Authorized, role:admin
```

### Storage

Argo CD is largely stateless, all data is persisted as Kubernetes objects, which in turn is stored in Kubernetes' etcd. Redis is only used as a throw-away cache and can be lost. When lost, it will be rebuilt without loss of service.

### High Availability

Upstream provides methods and [documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/high_availability/#argocd-dex-server-argocd-redis) for deploying argocd in HA.

Requirements:
- HA installation will require at least three different nodes due to pod anti-affinity roles in the specs.
- `controller.replicas` and the `ARGOCD_CONTROLLER_REPLICAS` controller environment variable must have matching values (see below).
- ArgoCD is pre-configured with the understanding of only three total redis servers. The package deploys a master with 3 replicas by default.

Caveats:
- The argocd-dex-server uses an in-memory database, and two or more instances would have inconsistent data.

The following is an example of how to modify the Big Bang values to accommodate a HA deployment.

```yaml
addons:
  argocd:
    values:
      controller:
        replicas: 3
        env:
        - name: "ARGOCD_CONTROLLER_REPLICAS"
          value: "3"
      server:
        replicas: 3
      repoServer:
        replicas: 3
```

For additional information about an ArgoCD high availability deployment visit [ArgoCD High Availability](https://argo-cd.readthedocs.io/en/stable/operator-manual/installation/#high-availability)

### UI

ArgoCD includes a UI, which is accessible at a configurable URL. The UI can be used to view, manage, and create applications.

ArgoCD is Istio injected and the VirtualService resource is accessible externally from the cluster at "argocd.{{ .Values.domain }}" but can be configured via the following values in the bigbang chart:

```yaml
domain: bigbang.dev
istio:
  enabled: true
  argocd:
    # -- Toggle Istio VirtualService creation
    enabled: true
    # -- Set Annotations for VirtualService
    annotations: {}
    # -- Set Labels for VirtualService
    labels: {}
    # -- Set Gateway for VirtualService
    gateways:
      - istio-system/main
    # -- Set Hosts for VirtualService
    hosts:
      - argocd.{{ .Values.domain }}

```

If you need to alter the VirtualService host out of band you will also need to configure the argocd `config.url` to match:

```yaml
addons:
  argocd:
    values:
      # -- Manage Argo CD configmap (Declarative Setup)
      ## Ref: https://github.com/argoproj/argo-cd/blob/master/docs/operator-manual/argocd-cm.yaml
      configEnabled: true
      # -- [General Argo CD configuration]
      # @default -- See [values.yaml]
      config:
        # Argo CD's externally facing base URL (optional). Required when configuring SSO
        url: https://argocd.bigbang.dev        
```

### Logging

Argo CD logs payloads of most API requests except request that are considered sensitive, such as /cluster.ClusterService/Create, /session.SessionService/Create etc. The full list of method can be found in server/server.go For more information, see [ArgoCD Logs](https://argo-cd.readthedocs.io/en/stable/operator-manual/security/#logging).

An example of how to modify the argocd logging values within Big Bang is as follows:

```yaml
addons:
  argocd:
    values:
      controller:
        # -- Set the logging level. (One of: `debug`, `info`, `warn`, `error`)
        logLevel: debug
        # -- Application controller log format. Either `text` or `json`
        logFormat: text
      server:
        # -- Set the logging level. (One of: `debug`, `info`, `warn`, `error`)
        logLevel: debug
        # -- Application controller log format. Either `text` or `json`
        logFormat: text    
      repoServer:
        # -- Set the logging level. (One of: `debug`, `info`, `warn`, `error`)
        logLevel: debug
        # -- Application controller log format. Either `text` or `json`
        logFormat: text           
```

_Note:_ within Big Bang, logs are captured by fluentbit or promtail and shipped to your enabled logging stack (ECK by default, PLG is also available).

### Monitoring

ArgoCD exposes prometheus metrics in the API of each service if the config.yaml used by that service has the metrics.enabled keys set to enabled and `metrics.servicemonitor` keys set to true. Each service exports its own metrics and is typically scraped by a Prometheus installation to gather the metrics.

The Big Bang ArgoCD Helm chart has been modified to use your `monitoring:` values in Big Bang to automatically toggle metrics on/off.

### Health Checks

Argo CD provides built-in health assessment for several standard Kubernetes types, which is then surfaced to the overall application health status as a whole.

For more information, see [ArgoCD Resource Health](https://argo-cd.readthedocs.io/en/stable/operator-manual/health/).
