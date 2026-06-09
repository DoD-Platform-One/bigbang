# Big Bang Capabilities
Big Bang is designed with capabilities that fall into six categories: Architecture, which includes the overall data flow of Big Bang and its features; Security and Compliance features, which provide easy-to-manage protection, monitoring, incident response, and management tools to maintain consistency; Observability capabilities, which provide dashboard visibility into metrics, distribution, and alerts; Developer tools, which provides four main tools to help for application deployment, artifact management, quality analysis, and code management; Operations features, which cover day-to-day procedures, troubleshooting, and upgrades; and Package Management, which includes, core packages, add-on packages, and community packages.

### Architecture
Big Bang's architecture design is represented [here](concepts/architecture.md) in diagrams for the following data flows:
- Kube API server webhooks 
- Logs data
- Metrics data
- Network encryption and ingress

### Security and Compliance
Big Bang has the following features to support security and compliance for its users:
- Istio service mesh with mutual TLS
- Kyverno policy engine for admission control
- Runtime security with vulnerability scanning
- Supply chain security with image signing

Go [here](concepts/security-model.md) for further information about Big Bang's security model.

### Observability
Big Bang includes the following features that increase visibility into operations:
- Prometheus and Grafana for metrics and dashboards
- Grafana alloy for log aggregation and analysis (optionally, Elasticsearch and Kibana can be used for this as an alternative).
- Tempo for distributed tracing
- Alertmanager for notification management

### Developer Tools
Big Bang uses the following developer tools to support continued development:
- GitLab for source code management and CI/CD
- ArgoCD for application deployment and management
- Nexus for artifact and dependency management
- SonarQube for code quality and security analysis

For information about Big Bang's GitOps workflow, go [here](concepts/git-ops-workflow.md).

### Operations
The following links provide more information on the day-to-day management and maintenance of Big Bang:
- **[Operations](operations/)**: Monitoring, backup, and maintenance procedures
- **[Troubleshooting](operations/troubleshooting/)**: Diagnose and resolve common issues
- **[Upgrades](operations/upgrades.md)**: Version management and upgrade procedures

### Packages
Big Bang's scope is to provide publicly available installation manifests for packages required to adhere to the DoD DevSecOps Reference Architecture and additional useful utilities. Big Bang packages are broken into three categories:


- **[Core Packages](packages/core/)**: A group of capabilities required by the DoD DevSecOps Reference Architecture, that are supported directly by the Big Bang development team. The specific capabilities that are considered core currently are Service Mesh, Policy Enforcement, Logging, Monitoring, and Runtime Security.
- **[Add-on Packages](packages/addons/)**: Any packages/capabilities that the Big Bang development team directly supports that do not fall under the above core definition. These serve to extend the functionality/features of Big Bang.
- **[Community Packages](https://repo1.dso.mil/big-bang/product/community)**: Any packages that are maintained by the broader Big Bang community (e.g., users and/or vendors). These packages could be alternatives to core or add-on packages, or even entirely new packages to help extend usage/functionality of Big Bang.

(Go [here](packages/) for a complete list of available packages.)

In order for an installation of Big Bang to be a valid installation/configuration, you must install/deploy a core package of each category.

Big Bang also builds tooling around the testing and validation of Big Bang packages. These tools are provided as-is, without support.

Big Bang is intended to be used for deploying and maintaining a DoD hardened and approved set of packages into a Kubernetes cluster.  Deployment and configuration of ingress/egress, load balancing, policy auditing, logging, and/or monitoring are handled via Big Bang.  Additional packages (e.g., ArgoCD and GitLab) can also be enabled and customized to extend Big Bang's baseline.  Once deployed, the Kubernetes cluster can be used to add mission specific applications.

Go [here](concepts/package-management.md) for further information about Big Bang's concept for package management.