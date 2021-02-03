# Big Bang Packages

Each Big Bang Package is present in the [Big Bang Package](https://repo1.dso.mil/platform-one/big-bang/apps) repository and broken up into several sub-groupings.

Each package has _at least_ two `CODEOWNERS`.  Responsibilities are outlined [here](ApplicationOwners.md).

[[_TOC_]]

## Dependencies

```mermaid
graph TB
  subgraph "Core"
  subgraph "Logging"
  LoggingElastic(Elasticsearch)
  LoggingKibana(Kibana)
  LoggingECK(ECK)
  LoggingElastic  --> LoggingECK
  LoggingKibana  --> LoggingECK
  LoggingKibana --> LoggingElastic
  Fluentd --> LoggingElastic
  end
  subgraph "Monitoring"
  Grafana --> Prometheus
  Thanos
  end
  ServiceMesh
  ArgoCD
  
  ClusterAuditor --> LoggingECK
  ClusterAuditor --> OPA(Policy Enforcement)
  end      

  subgraph "Package Utilities"
    Postgres
    MinIO(S3 Compatible Storage)
    Redis
    MySQL
    MongoDB
  end

  subgraph "Security"
  Keycloak --> Postgres
  Anchore(Anchore Enterprise) --> Postgres
  Twistlock
  end

  subgraph "Developer Tools"
    GitLab --> GitLabRunners(GitLab Runners)
    GitLab --> MinIO
    GitLab --> Redis
    GitLab --> Postgres
    Sonarqube --> Postgres
  end

  subgraph "Collaboration Tools"
    Jira --> Postgres
    Confluence --> Postgres
    MatterMost --> MinIO
  end

```


## Core

Core packages are supported Big Bang packages that have to be enabled and are located at [Big Bang Core](https://repo1.dso.mil/platform-one/big-bang/apps/core).  Core packages are platform/admin level packages that are leveraged by other packages.

```mermaid
graph TB
  subgraph "Core"
  subgraph "Logging"
  LoggingElastic(Elasticsearch)
  LoggingKibana(Kibana)
  LoggingECK(ECK)
  LoggingElastic  --> LoggingECK
  LoggingKibana  --> LoggingECK
  LoggingKibana --> LoggingElastic
  Fluentd --> LoggingElastic
  end
  subgraph "Monitoring"
  Grafana --> Prometheus
  Thanos
  end
  ServiceMesh
  ArgoCD
  Twistlock
  
  ClusterAuditor --> LoggingECK
  ClusterAuditor --> OPA(Policy Enforcement)
  end      
```

### ArgoCD

Product:

* [ArgoCD](https://argoproj.github.io/argo-cd/)

Repository:

* [ArgoCD Repo](https://repo1.dso.mil/platform-one/big-bang/apps/core/argocd)

Dependency: None

Owners:

* @joshwolf - Rancher Federal
* @karchaf

Understudy:

*  @kavitha

### Service Mesh

Current implementation of Service Mesh is provided by Istio. Service Mesh should be the first Package deployed to ensure other applications are operating with visibility and security.

Product:

* [Istio](https://istio.io/)

Repository:

* [Istio-operator](https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-operator)
* [Istio-controlplane](https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-controlplane)

Dependency: None

Owners:

* @runyontr - Runyon Solutions

Understudy:

* Chris McGrath
* @kavitha
* @kenna81

### Logging

The logging package is responsible for deploying Elasticsearch, Kibana, and Fluentd.  It is also responsible for configuring the logging pipelines to aggregate all running containers logs for viewing by both Cluster Owners and Application Operators.

The logging capability is comprised of:

* Elastic Cloud on Kubernetes (ECK) Operator
* Elasticsearch
* Kibana
* Fluentd
* Logging Operator

Repository: 
* [Elasticsearch-kibana](https://repo1.dso.mil/platform-one/big-bang/apps/core/elasticsearch-kibana)
* [Fluentbit](https://repo1.dso.mil/platform-one/big-bang/apps/core/fluentbit)
* [Eck-operator](https://repo1.dso.mil/platform-one/big-bang/apps/core/eck-operator)

Dependencies:

* RWO StorageClass

Owners:

* @kavitha
* @ryan.j.garcia

Understudy:

* @evan.rush

### Policy Enforcement

The Policy Enforcement Package installs the Open Policy Agent Gatekeeper [Operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/).

Product:

* [OPA Gatekeeper](https://github.com/open-policy-agent/gatekeeper)
* [Open Policy Agent](https://www.openpolicyagent.org/)

Repository:

* [Policy Repo](https://repo1.dso.mil/platform-one/big-bang/apps/core/policy)

Dependencies: None

Owners:

* @runyontr - Runyon Solutions
* @karchaf - Cloud Fit Software

Understudy

* @agudem
* @kavitha

### Monitoring

Monitoring is provided by Prometheus, Grafana and Thanos.

Product:

* [Prometheus](https://prometheus.io/)
* [Grafana](https://grafana.com/)
* [Thanos](https://thanos.io/)

Repository:

* [Monitoring Repo](https://repo1.dso.mil/platform-one/big-bang/apps/core/monitoring)

Dependencies: None

Owners:

* @lynnStill
* @ryan.j.garcia

### Cluster Auditor

Cluster Auditor is an internal tool that provides compliance information to Cluster Owners and Application Developers for insight into Reference DevSecOps compliance

Product:

Repository: [Cluster Auditor](https://repo1.dso.mil/platform-one/big-bang/apps/core/cluster-auditor)

Dependencies:

* [Logging](#Logging)
* [OPA Gatekeer](#policy-enforcement)

Owners:

* @runyontr - Runyon Solutions
* @thomas.burton - iSenpai

Understudy:

* @agill17
* @kenna81

Repository:
* [Cluster Auditor Repo](https://repo1.dso.mil/platform-one/big-bang/apps/core/cluster-auditor)

### Twistlock

Twistlock provides runtime vulnerability detection

Product:

* [Twistlock](https://www.twistlock.com/labs-/)

Repository: [Twistlock Repo](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/twistlock)

Dependencies:

* RWO StorageClass

Owners:

* @runyontr - Runyon Solutions
* @thomas.burton - iSenpai

## Addons
Addons are supported Big Bang packages that come disabled by default.

### Security Tools

Security Tools are hosted here: [Security Tools](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools)

```mermaid
graph TB  

  subgraph "Package Utilities"
    Postgres
  end

  subgraph "Security"
  Keycloak --> Postgres
  Anchore(Anchore Enterprise) --> Postgres
  end
```

#### Keycloak

Keycloak provides SSO to applications.

Product:

* [Keycloak](https://www.keycloak.org/)
* [Postgres](https://www.postgresql.org/)

Repository: [Keycloak](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/keycloak)

Dependencies:

* Postgres

Owners:

* @megamind
* @joshwolf

Understudy:

* @agudem
* @kenna81

#### Anchore Enterprise

Product:

* [Anchore Enterprise](https://anchore.com/enterprise/)

Repository: [Anchore Enterprise Repo](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/anchore-enterprise)

Dependencies:

* postgres

Owners:

* @thomas.burton - iSenpai
* @james.peterson - Anchore

### Developer Tools

Developer Tools are hosted here: [Developer Tools](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools)

```mermaid
graph TB

  subgraph "Application Utilities"
    Postgres
    MinIO(S3 Compatible Storage)
    Redis
  end


  subgraph "Package Tools"
    GitLab --> GitLabRunners(GitLab Runners)
    GitLab --> MinIO
    GitLab --> Redis
    GitLab --> Postgres
    Sonarqube --> Postgres
  end
```

#### GitLab

GitLab is a product for providing DevOps including planning, code hosting, and CICD

Product:

* [GitLab](https://docs.gitlab.com/)

Repository:

* [GitLab Repo](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab)

Dependencies:

* postgres
* S3 compatible object store (ex: [Minio](#minio))
* Redis
* RWO StorageClass

Owners:

* @ryan.j.garcia
* @LynnStill

#### GitLab Runners

GitLab Runners are pods that run jobs for GitLab CI/CD

Product:

* [GitLab Runners](https://docs.gitlab.com/runner/)

Repository:

* [GitLab Runners Repo](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab-runner)

Dependencies:

* [GitLab](#gitlab)

Owners:

* @ryan.j.garcia
* @LynnStill

Understudies
* @kevin.wilder

#### Sonarqube

Sonarqube provides code reviews for code quality and security

Product:

* [Sonarqube](https://www.sonarqube.org/)

Repository:

* [Sonarqube Repo](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/sonarqube)

Dependencies:

* postgres
* RWO StorageClass

Owners:

* @kevin.wilder
* @LynnStill

#### Fortify

Fortify provides code 

Product:

* 

Repository:

* [Fortify Repo](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/fortify)

Dependencies:

Owners:

* @kevin.wilder
* @LynnStill

### Collaboration Tools

Collaboration tools are hosted here: [Collaboration Tools](https://repo1.dso.mil/platform-one/big-bang/apps/collaboration-tools)

```mermaid
graph TB
  subgraph "Package Utilities"
    Postgres
    MinIO(S3 Compatible Storage)
  end

  subgraph "Collaboration Tools"
    Jira --> Postgres
    Confluence --> Postgres
    MatterMost --> MinIO
  end

```

#### Confluence

Confluence provides a centralized workspace for collaborating on documentation

Product:

* [Confluence](https://www.atlassian.com/software/confluence)

Repository:

* [Confluence Repo](https://repo1.dso.mil/platform-one/big-bang/apps/collaboration-tools/confluence)

Dependencies:

* Postgres
* RWM StorageClass (if HA)

Owners:

* @matt.kaiser
* @branden.cobb


#### Jira

Development tool for planning and tracking team tasks

Product:

* [Jira](https://www.atlassian.com/software/jira)

Repository:

* [Jira Repo](https://repo1.dso.mil/platform-one/big-bang/apps/collaboration-tools/jira)

Dependencies:

* Postgres
* RWM StorageClass (if HA)

Owners:

* @matt.kaiser
* @branden.cobb

#### Mattermost

Mattermost is an open sourced messaging platform.

Product:

* [Mattermost](https://mattermost.com/)

Repository:

* [Mattermost Repo](https://repo1.dso.mil/platform-one/big-bang/apps/collaboration-tools/mattermost)ß

Dependencies:

* S3 compatible object store (ex: [Minio](#minio))

Owners:

* @ryan.j.garcia
* @kevin.wilder

### Package Utilities

Application utilities are deployments of utilities used by one or more packages.  They are usually not user facing, and are dependencies of user facing packages.

A clear an obvious example of this is PostgreSQL.

```mermaid
graph TB
  subgraph "Package Utilities"
    Postgres
    MinIO(S3 Compatible Storage)
    Redis
    MySQL
    MongoDB
  end

```

#### PostgreSQL

Product:

* [PostgreSQL](https://www.postgresql.org/)

Repository:

* TBD

Owners:

* TBD
* TBD

#### Minio

Minio provides S3 compatible object storage

Product:

* [MinIO](https://min.io/)

Repository: TBD

Dependencies: None

Owners:

* @kevin.wilder - Dark Wolf Solutions
* @branden.cobb

#### MySQL

Product:

* [MySQL](https://www.mysql.com/)

Repository:

* TBD

Owners:

* TBD
* TBD

#### MongoDB

Product:

* [MongoDB](https://www.mongodb.com/)

Repository:

* TBD

Owners:

* TBD
* TBD

### Sandbox

The [Sandbox](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox) is an area for packages that are currently being or will be worked that do not yet meet the requirements of a supported package.  Due to the fluidity of sandbox apps, they are not tracked in the charter.

Note, this is _not_ a place where packages go to die.  If a package is abandoned for whatever reason it will be archived.

To graduate from a sandbox package, it must meet the requirements outlined in this charter.
