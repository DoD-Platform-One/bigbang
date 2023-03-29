# Packages

Big Bang includes many different packages that provide services to the ecosystem.  Each of these packages is deployed by a Helm chart located in a repository under [Big Bang's Packages Group](https://repo1.dso.mil/platform-one/big-bang/apps).  The packages are broken up into several categories listed below.  Sometimes packages are tightly coupled and grouped together in a stack.  When using a stack, all packages in the stack will be deployed.

[[_TOC_]]

## Technical Oversight Committee (TOC)

The Big Bang TOC supports users and contributors of the Big Bang ecosystem.  If you would like to add, modify, or remove packages in Big Bang, we encourage you to attend the TOC to discuss your ideas.  You can find details in [the TOC repository](https://repo1.dso.mil/platform-one/bbtoc).

## Dependency Tree

Several of Big Bang's packages have dependencies on other packages.  A Dependency exists if the package would have a significant (or total) loss in functionality if the dependency was not present.

```mermaid
flowchart LR
  subgraph Core
    direction BT

    subgraph L[Logging]
      subgraph EFK[Default]
        Kibana & Fluentbit --> Elastic
      end
      subgraph PLG[Alternative]
      style PLG stroke-dasharray: 10 10
        Promtail[Promtail*] --> Loki[Loki*]
      end
    end

    subgraph M[Monitoring]
      Grafana --> Prometheus
      Grafana -.-> Loki
    end

    subgraph PE[Policy Enforcement]
      subgraph CA[Default]
      direction BT
        ClusterAuditor --> OPA[OPA Gatekeeper]
      end
      subgraph KyvernoStack[Alternative]
      style KyvernoStack stroke-dasharray: 10 10
      direction BT
        KyvernoReporter[Kyverno Reporter*] --> Kyverno[Kyverno*]
      end
    end

    subgraph RS[Runtime Security]
      subgraph TL[Default]
        Twistlock[Prisma Cloud Compute]
      end
    end

    subgraph DT[Distributed Tracing]
      subgraph J[Default]
        Jaeger ----> Elastic
      end
      subgraph T[Alternative]
      style T stroke-dasharray: 10 10
        Tempo[Tempo*] -.-> Grafana
      end
    end

    subgraph SM[Service Mesh]
      Jaeger --> Istio
      Tempo -.-> Istio
      Kiali --> Jaeger & Istio & Prometheus
    end
  end
```

```mermaid
flowchart LR
  subgraph AddOns
    subgraph AppUtils[Application Utilities]
      MinIO
    end

    subgraph ClusterUtils[Cluster Utilities]
    direction BT
      ArgoCD
      Metrics[Metrics Server]
      Velero
    end

    subgraph "Security"
    direction BT
      Anchore
      Authservice --> I[Istio]
      Keycloak
      Vault[Vault*]
    end

    subgraph "Collaboration"
    direction BT
      Mattermost
    end

    subgraph "Developer Tools"
    direction BT
      GLRunners[GitLab Runners] --> GitLab
      Nexus[Nexus Repository]
      Sonarqube
    end
  end
```

> Footnotes:
>
> - Dotted lines in `Core` indicate a package that is not enabled by default
> - The following were left off the chart to keep it simple
>   - Most packages depend on Istio for encrypted traffic and ingress to interfaces.
>   - Some packages have operators that are deployed prior to the package and manage the package's state.

## Core

Core packages make up the foundation of Big Bang.  At least one of the supported stacks listed in each category must be enabled to be considered a Big Bang cluster.  These packages are designed to provide administrative support for other packages.

### Service Mesh

A service mesh is a dedicated infrastructure layer for making service-to-service communication safe, fast, and reliable.  It provides fine-grained control and enforcement of network routing into, out of, and within the cluster.  It can also supply end-to-end traffic encryption, authentication, and authorization.

|Default|Stack|Package|Function|Repositories|
|--|--|--|--|--|
|X|Istio|Istio Operator|Operator|[istio-operator](https://repo1.dso.mil/big-bang/product/packages/istio-operator)|
|X|Istio|[Istio](./istio.md)|Control Plane|[istio-controlplane](https://repo1.dso.mil/big-bang/product/packages/istio-controlplane)|
|X|Istio|[Kiali](./kiali.md)|Management Console|[kiali](https://repo1.dso.mil/big-bang/product/packages/kiali)|

### Logging

A logging stack is a set of scalable tools that can aggregate logs from cluster services and provide real-time queries and analysis.  Logging is typically comprised of three components: a forwarder, storage, and a visualizer.

|Default|Stack|Package|Function|Repositories|
|--|--|--|--|--|
| |EFK|Elastic Cloud on Kubernetes (ECK) Operator|Operator|[eck-operator](https://repo1.dso.mil/big-bang/product/packages/eck-operator)
| |EFK|[Elasticsearch / Kibana](./elasticsearch-kibana.md)|Storage & Visualization|[policy](https://repo1.dso.mil/big-bang/product/packages/policy)|
| |EFK|[Fluentbit](./fluentbit.md)|Forwarder|[fluentbit](https://repo1.dso.mil/big-bang/product/packages/fluentbit)|
|X|PLG|[Loki](./loki.md)|Storage|[loki](https://repo1.dso.mil/big-bang/product/packages/loki)|
|X|PLG|[Promtail](./promtail.md)|Forwarder|[promtail](https://repo1.dso.mil/big-bang/product/packages/promtail)|
> PLG stack uses Grafana, deployed in [monitoring](#monitoring), for visualization.

### Policy Enforcement

Policy Enforcement is the ability to validate Kubernetes resources against compliance, security, and best-practice policies.  If a resource violates a policy, the enforcement tool can deny access to the cluster, dynamically modify the resource to force compliance, or simply record the violation in an audit report.  Usually, a reporting tool accompanies the engine to help with analyzing and visualizing policy violations.

|Default|Stack|Package|Function|Repositories|
|--|--|--|--|--|
| |Gatekeeper|[OPA Gatekeeper](./opa-gatekeeper.md)|Engine & Policies|[policy](https://repo1.dso.mil/big-bang/product/packages/policy)|
| |Gatekeeper|[Cluster Auditor](./cluster-auditor.md)|Reporting|[cluster-auditor](https://repo1.dso.mil/big-bang/product/packages/cluster-auditor)|
|X|Kyverno|[Kyverno](./kyverno.md)|Engine|[kyverno](https://repo1.dso.mil/big-bang/product/packages/kyverno)|
|X|Kyverno|Kyverno Policies|Policies|[kyverno-policies](https://repo1.dso.mil/big-bang/product/packages/kyverno-policies)|
|X|Kyverno|Kyverno Reporter|Reporting|[kyverno-reporter](https://repo1.dso.mil/big-bang/product/packages/kyverno-reporter)|

### Monitoring

A monitoring stack is used to collect, visualize, and alert on time-series metrics from cluster resources.  Metrics are quantitative measurements that provide insight into the cluster.  Some examples of metrics include memory utilization, disk utilization, network latency, number of web queries, or number of database transactions.

|Default|Stack|Package|Function|Repositories|
|--|--|--|--|--|
|X|Monitoring|[Prometheus](./monitoring.md)|Collection & Alerting|[monitoring](https://repo1.dso.mil/big-bang/product/packages/monitoring)|
|X|Monitoring|[Grafana](./monitoring.md)|Visualization|[monitoring](https://repo1.dso.mil/big-bang/product/packages/monitoring)|

### Distributed Tracing

Distributed tracing is a method of tracking application transactions as they flows through cluster services.  It is a diagnosing technique to help characterize and troubleshoot problems from the user's perspective.

|Default|Package|Repositories|
|--|--|--|
| |[Jaeger](./jaeger.md)|[jaeger](https://repo1.dso.mil/big-bang/product/packages/jaeger)|
|X|[Tempo](./tempo.md)|[tempo](https://repo1.dso.mil/big-bang/product/packages/tempo)|

### Runtime Security

Runtime security is the active protection of containers running in the cluster.  This type of tool includes scanning for vulnerabilities, checking compliance, detecting threats, and preventing intrusions.  Many of these tools also include forensics and incident response features.

|Default|Package|Repositories|
|--|--|--|
| |[Prisma Cloud Compute](./twistlock.md) (AKA Twistlock) ![License Required](https://img.shields.io/badge/License_Required-orange)|[twistlock](https://repo1.dso.mil/big-bang/product/packages/twistlock)|
|X|[Neuvector](./neuvector.md)|[neuvector](https://repo1.dso.mil/big-bang/product/packages/neuvector)|

## Addons

Addons can be used to extend Big Bang with additional services.  All of the addons listed here are supported by the Big Bang team and integrated into the product.  There may be additional community supported Big Bang packages that are not listed here.  These packages are disabled in Big Bang by default.

### Storage Utilities

Storage utilities include packages that provide services to store and retrieve temporal or persistent data in the cluster.  This category includes databases, object storage, and data caching.  It is generally advantageous to use cloud based offerings instead of these to take advantage of scalability, availability, and resiliency (e.g. backup and restore).  However, for non-critical or on-prem deployments, these utilities offer a simpler and lower cost solution.

|Stack|Package|Function|Repository|
|--|--|--|--|
|MinIO|MinIO Operator|Operator|[minio-operator](https://repo1.dso.mil/big-bang/product/packages/minio-operator)|
|MinIO|[MinIO](./minio.md)|S3 Object Storage|[minio](https://repo1.dso.mil/big-bang/product/packages/minio)|

### Cluster Utilities

Cluster utilities add functionality to Kubernetes clusters rather than applications.  Examples include resource utilization, cluster backup and restore, continuos deployment, or load balancers.

|Package|Function|Repository|
|--|--|--|
|[ArgoCD](./argocd.md)|Continuous Deployment|[argocd](https://repo1.dso.mil/big-bang/product/packages/argocd)
|Metrics Server|Monitors pod CPU & memory utilization|[metrics-server](https://repo1.dso.mil/big-bang/product/packages/metrics-server)|
|[Velero](./velero.md)|Cluster Backup & Restore|[velero](https://repo1.dso.mil/big-bang/product/packages/velero)|

### Security

Security packages add additional security features for protecting services or data from unauthorized access or exploitation.  This includes things like identity providers (IdP), identity brokers, authentication (AuthN), authorization (AuthZ), single sign-on (SSO), security scanning, intrusion detection/prevention, and sensitive data protection.

|Package|Function|Repository|
|--|--|--|
|[Anchore](./anchore.md)|Vulnerability Scanner|[anchore-enterprise](https://repo1.dso.mil/big-bang/product/packages/anchore-enterprise)|
|[Authservice](./authservice.md)|Istio extension for Single Sign-On (SSO)|[authservice](https://repo1.dso.mil/big-bang/product/packages/authservice)|
|[Keycloak](./keycloak.md)|IdP, Identity Broker, AuthN/Z|[keycloak](https://repo1.dso.mil/big-bang/product/packages/keycloak)|
|[Vault](./vault.md)|Sensitive Data Access Control|[vault](https://repo1.dso.mil/big-bang/product/packages/vault)|

### Collaboration

Collaboration tools provide environments to help teams work together online.  Chatting, video conferencing, file sharing, and whiteboards are all examples of collaboration tools.

|Stack|Package|Function|Repository|
|--|--|--|--|
|Mattermost|Mattermost Operator|Operator|[mattermost-operator](https://repo1.dso.mil/big-bang/product/packages/mattermost-operator)|
|Mattermost|[Mattermost](./mattermost.md)|Chat|[mattermost](https://repo1.dso.mil/big-bang/product/packages/mattermost)|

### Developer Tools

Developer tools include packages that a programmer would use to plan, author, test, debug, or control code.  This includes repositories, bug / feature tracking, pipelines, code analysis, automated tests, and development environments.

|Stack|Package|Function|Repository|
|--|--|--|--|
|GitLab|[GitLab](./gitlab.md)|Code repository, issue tracking, release planning, security and compliance scanning, pipelines, artifact repository, wiki|[gitLab](https://repo1.dso.mil/big-bang/product/packages/gitlab)|
|GitLab|GitLab Runner|Executor for GitLab pipelines|[gitlab-runner](https://repo1.dso.mil/big-bang/product/packages/gitlab-runner)|
|Nexus|[Nexus Repository Manager](./nexusRepositoryManager.md)|Artifact repository|[nexus](https://repo1.dso.mil/big-bang/product/packages/nexus)
|Sonarqube|[Sonarqube](./sonarqube.md)|Static code analysis|[sonarqube](https://repo1.dso.mil/big-bang/product/packages/sonarqube)

## Further Information

You can find some additional details about features supported by each package by visiting [this document](../../packages.md).
