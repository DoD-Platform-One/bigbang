# Useful Background Contextual Information

## The purpose of this section is to help consumers of BigBang understand

* BigBang's scope: what it is and isn't, goals and non-goals
* The value add gained by using BigBang
* What to expect in terms of prerequisites for those interested in using BigBang
* Help those who want a deep drive concrete understanding of BigBang quickly come up to speed, via pre-reading materials, that can act as a self service new user orientation to point out features and nuances that new users wouldn't know to ask about.

## BigBang's scope: what it is and isn't, goals and non-goals

### What BigBang is

* BigBang is a Helm Chart that is used to deploy a DevSecOps Platform composed of IronBank hardened container images on a Kubernetes Cluster.
* See [/docs/README.md](../README.md#what-is-bigbang?) more details.

### What BigBang isn't

* BigBang by itself is not intended to be an End to End Secure Kubernetes Cluster Solution, but rather a reusable secure component/piece of a full solution.
* A Secure Kubernetes Cluster Solution, will have multiple components, that can each be swappable and in some cases considered optional depending on use case and risk tolerance:
  Example of some potential components in a full End to End Solution:
  * P1's Cloud Native Access Point to protect Ingress Traffic. (This can be swapped with an equivalent, or considered optional in an internet disconnected setup.)
  * Hardened Host OS
  * Hardened Kubernetes Cluster (BigBang assumes ByoC, Bring your own Cluster) (The BigBang team recommends consumers who are interested in a full solution, partner with Vendors of Kubernetes Distributions to satisfy the prerequisite of a Hardened Kubernetes Cluster.)
  * Hardened Applications running on the Cluster (BigBang helps solve this component)

## Value add gained by using BigBang

* Compliant with the [DoD DevSecOps Reference Architecture Design](https://dodcio.defense.gov/Portals/0/Documents/DoD%20Enterprise%20DevSecOps%20Reference%20Design%20v1.0_Public%20Release.pdf)
* Can be used to check some but not all of the boxes needed to achieve a cATO (Continuous Authority to Operate.)
* Uses hardened IronBank Container Images. (left shifted security concern)
* GitOps adds security benefits, and BigBang leverages GitOps, and can be further extended using GitOps.
  Security Benefits of GitOps:
  * Prevents config drift between state of a live cluster and IaC/CaC source of truth: By avoiding giving any humans direct kubectl access, by only allowing humans to deploy via git commits, out of band changes are limited.
  * Git Repo based deployments create an audit trail.
  * Secure Configurations become reusable, which lowers the burden of implementing secure configurations.
* Lowers maintainability overhead involved in keeping the images of the DevSecOps Platform's up to date and maintaining a secure posture over the long term. This is achieved by pairing the GitOps pattern with the Umbrella Helm Chart Pattern.
  Let's walk through an example:
  * Initially a kustomization.yaml file in a git repo will tell the Flux GitOps operator (software deployment bot running in the cluster), to deploy version 1.0.0 of BigBang. BigBang could deploy 10 helm charts. And each helm chart could deploy 10 images. (So BigBang is managing 100 container images in this example.)
  * After a 2 week sprint version 1.1.0 of BigBang is released. A BigBang consumer updates the kustomization.yaml file in their git repo to point to version 1.1.0 of the BigBang Helm Chart. That triggers an update of 10 helm charts to a new version of the helm chart. Each updated helm chart will point to newer versions of the container images managed by the helm chart.
  * So when the end user edits the version of 1 kustomization.yaml file, that triggers a chain reaction that updates 100 container images.
  * These upgrades are pre-tested. The BigBang team "eats our own dogfood". Our CI jobs for developing the BigBang product, run against a BigBang dogfood Cluster, and as part of our release process we upgrade our dogfood cluster, before publishing each release. (Note: We don't test upgrades that skip multiple minor versions.)
  * Auto updates are also possible by setting kustomization.yaml to 1.x.x, because BigBang follows semantic versioning, flux is smart enough to read x as the most recent version number.
* DoD Software Developers get a Developer User Experience of "SSO for free". Instead of developers coding SSO support 10 times for 10 apps. The complexity of SSO support is baked into the platform, and after an Ops team correctly configures the Platform's SSO settings, SSO works for all apps hosted on the platform. The developer's user experience for enabling SSO for their app then becomes as simple as adding the label istio-injection=enabled (which transparently injects mTLS service mesh protection into their application's Kubernetes YAML manifest) and adding the label protect=keycloak to each pod, which leverages an EnvoyFilter CustomResource to auto inject an SSO Authentication Proxy in front of the data path to get to their application.

## Acronyms

* CSP: Cloud Service Provider
* L4 LB: Layer 4 Load Balancer
* KMS: Key Management System / Encryption as a Service (AWS/GCP KMS, Azure Key Vault, HashiCorp Transient Secret Engine)
* PGP: Pretty Good Privacy (Asymmetric Encryption Key Pair, where public key is used to encrypt, private key used to decrypt)
* SOPS: "Secret Operations" CLI tool by Mozilla, leverages KMS or PGP to encrypt secrets in a Git Repo. (Flux and P1's modified ArgoCD can use SOPS to decrypt secrets stored in a Git Repo.)
* cATO: continuous Authority to Operate
* AO: Authorizing Official (Government Official who determines OS and Kubernetes Cluster hardening requirements, that result in a level of acceptable remaining risk that they're willing to sign off on for a Kubernetes Cluster to receive an ATO, and a BigBang Cluster to receive a cATO)
* IaC: Infrastructure as Code
* CaC: Configuration as Code
* CAC: Common Access Card  

## Prerequisites

* Prerequisites vary depending on deployment scenario
* [Prerequisites can be found here](../guides/prerequisites)

## Additional Useful Background Contextual Information

* We are still migrating some docs from IL2 Confluence, and the BigBang Onboarding Engineering Cohort into to this repositories' /docs folder, the planned future state is for this to be a primary location for docs going forward. (Any docs hosted in other repositories, will at least have pointers hosted here.)
* There are multiple implementations of Helm Charts (Helm repositories, .tgz, and files and folders in a git repo), whenever P1 refers to a helm chart we're always referring to the files and folders in a git repo implementation, which is stored in /chart folder in a git repo.
* Additional pre-reading materials to develop a better understanding of BigBang before deploying can be found in this understanding_bigbang folder.
* If you see an issue with docs or packages, please [open an issue against the main BigBang Repo](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues), instead of the individual package repo.

## Note about Snippets of Architecture Diagrams in this folder

* The intent of sharing Architecture Diagrams is to:
  * Act as a starting point upon which further understanding can be built
  * Improve a users understanding of how BigBang components fit together, so that if the user needs to modify components or workflows flows to fit their use case they'll have an idea of what the modification might look like
  * Show potential use cases for some of BigBang's core components
* These Architecture Diagrams are NOT intended to:
  * Reflect an accurate default configuration
  * Prescriptively say you must do things this way
* These Architecture Diagrams should be taken with a grain of salt:
  It's difficult to make a generic diagram with high accuracy. BigBang's Helm Values are variables, some values can produce significantly different workflows. Nuances specific to the deployment environment and hardened configurations like SELinux & Istio CNI can slightly effect parts of implementation details.
