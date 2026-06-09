# Why Use Big Bang?
Big Bang is a declarative, commercially supported DevSecOps platform that fundamentally accelerates the delivery of secure software. By providing a pre-integrated suite of hardened tools, Big Bang significantly reduces the time required to achieve an Authority to Operate (ATO). It eliminates the need for organizations to build and maintain bespoke infrastructure, allowing teams to instantly inherit a proven security baseline and focus entirely on mission-critical application development.
## What are the benefits of using Big Bang?

Big Bang provides the following key benefits to users:
* Compliant with the [DoD DevSecOps Reference Architecture Design](https://dodcio.defense.gov/Portals/0/Documents/Library/DoD%20Enterprise%20DevSecOps%20Reference%20Design%20-%20CNCF%20Kubernetes%20w-DD1910_cleared_20211022.pdf).
* Accelerates cATO/ATO: Drastically reduces the compliance burden by providing pre-authorized, hardened components. Big Bang satisfies a significant portion of required technical security controls out of the box, allowing organizations to leverage "inherited controls," rather than starting their compliance journey from scratch.
* Left shift supply chain security concerns using hardened Iron Bank container images.
* GitOps adds security benefits, and Big Bang leverages GitOps, and can be further extended using GitOps.
  Security Benefits of GitOps:
  * Prevents configuration drift between state of a live cluster and IaC/CaC source of truth: By avoiding giving any humans direct `kubectl` access, by only allowing humans to deploy via git commits, out of band changes are limited.
  * Git Repo based deployments create an audit trail.
  * Reusable secure configurations lowers the burden of implementing secure configurations.
* Lowers maintainability overhead involved in keeping the images of a DevSecOps Platform up to date and maintaining a secure posture over the long term. This is achieved by pairing the GitOps pattern with the Umbrella Helm Chart Pattern.
  Let's walk through an example:
  * Initially a `kustomization.yaml` file in a git repo will tell the Flux GitOps operator (software deployment bot running in the cluster), to deploy version 1.0.0 of Big Bang. Big Bang could deploy 10 helm charts and each helm chart could deploy 10 images. (In this example, Big Bang is managing 100 container images.)
  * After a two-week sprint, version 1.1.0 of Big Bang is released. A Big Bang consumer updates the `kustomization.yaml` file in their git repo to point to version 1.1.0 of the Big Bang Helm Chart. That triggers an update of 10 helm charts to a new version of the helm chart. Each updated helm chart will point to newer versions of the container images managed by the helm chart.
  * When the end user edits the version of one `kustomization.yaml` file, that triggers a chain reaction that updates 100 container images in the cluster.
  * These upgrades are pre-tested. The Big Bang team "eats our own dogfood." Our CI jobs for developing the Big Bang product, run against Big Bang Release Cluster, and as part of our release process we upgrade our Big Bang Release Cluster, before publishing each release.
  > **Note:** Big Bang only supports and tests successive upgrades. Skipping minor versions is not supported and may result in broken deployments.
  
  >**Note:** While Flux supports wildcard versioning (e.g., `1.x.x`) to automatically track the latest release, this is **not recommended for production environments**. Automatic version advancement bypasses change control processes. Pin to an explicit version in production and upgrade deliberately.
  * Auto updates are also possible by setting kustomization.yaml to 1.x.x, because Big Bang follows semantic versioning per the [Big Bang README](../../README.md#release-schedule), and flux is smart enough to read x as the most recent version number.
* SSO support is included in the Big Bang platform offering. Operations teams can leverage Big Bang's free Single Sign On capability by deploying the [Keycloak project](https://www.keycloak.org/). Using Keycloak, an ops team configures the platform SSO settings so that SSO can be leveraged by all apps hosted on the platform. For details, see the [SSO Readme](../community/development/package-integration/sso.md). Once Authservice is configured, to enable SSO for an individual app, developers need only ensure the presence of the two following labels:
  - __Namespace__ `istio-injection=enabled`: transparently injects mTLS service mesh protection into their application's Kubernetes YAML manifest
  - __Pod__ `protect=keycloak`: declares an EnvoyFilter CustomResource to auto inject an SSO Authentication Proxy in front of the data path to get to their application

## Team Benefits

Additionally, Big Bang provides a number of benefits depending on the type of team using it, Platform Teams, Development Teams, and Organizations will each find key features that are especially useful to their efforts and concerns.

### For Platform Teams
Since platform teams are tasked with maintaining environments, they need easy-to-use and consistent security. Big Bang provides that by having platform and security be a focus of our out-of-the-box offerings
- **Rapid Platform Setup**: Deploy a production-ready Kubernetes platform in hours, not months
- **Security by Default**: Built-in security controls including network micro-segmentation via Istio, automated policy enforcement using OPA Gatekeeper or Kyverno, and encrypted secrets management native to the GitOps flow.

- **Operational Excellence**: Integrated observability (Prometheus, Grafana, Promtail) provides a single pane of glass out of the box. This correlates metrics and logs across the entire service mesh, eliminating the blind spots that plague fragmented environments.

- **Standardization**: Eliminates "snowflake" clusters. Instead of platform teams hand-crafting individual environments which makes disaster recovery and compliance audits incredibly painful, Big Bang ensures every environment (Dev, Test, Prod) is an exact, reproducible replica governed by Git.

### For Development Teams
With Big Bang, development teams can focus on application development with state-of-the-art tooling without concerning themselves with development operations and platform maintenance. This leads to a more focused and efficient development pipeline.
- **Focus on Applications**: Developers consume the platform as a service. Because the platform team uses Big Bang to handle the underlying ingress, logging, and security mesh, developers can simply commit their code and rely on the platform to handle the complex routing and security requirements.
- **Modern Toolchain**: Access to industry-leading, pre-hardened development and deployment tools directly from Iron Bank, such as GitLab Runners, ArgoCD, SonarQube, and Fortify.
- **Secure by Design**: Security controls integrated into the development workflow
- **Self-Service**: GitOps-driven deployments with minimal operational overhead

### For Organizations
For organizations, there is a greater concern about cost, compliance, and risk awareness, Big Bang's features address those concerns in the following ways:
- **Compliance**: Built-in support for NIST, FedRAMP, and DoD security standards
- **Cost Efficiency**: Drastically reduces the engineering hours spent on infrastructure integration and maintenance. Organizations avoid the sunk cost of "reinventing the wheel" and can reallocate those engineering resources toward revenue-generating or mission-critical features.
- **Risk Reduction**: Mitigates the risk of software supply chain attacks by exclusively utilizing rigorously scanned, DoD-approved Iron Bank containers. It also prevents compliance drift, ensuring that the system that was audited on day one remains secure on day one hundred.
- **Vendor Independence**: Open-source foundation with commercial support options
