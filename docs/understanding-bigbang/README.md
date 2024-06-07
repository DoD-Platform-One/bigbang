# Useful Background Contextual Information

Start with the [Documentation README](../README.md), which includes the following sections:

* [What is Big Bang?](../README.md#what-is-big-bang)
* [What *isn't* Big Bang?](../README.md#what-big-bang-isnt)
* [Benefits of Big Bang](../README.md#benefits-of-using-big-bang)

## Acronyms

* **CSP**: Cloud Service Provider
* **L4 LB**: Layer 4 Load Balancer
* **KMS**: Key Management System/Encryption as a Service (AWS/GCP KMS, Azure Key Vault, HashiCorp Transient Secret Engine)
* **PGP**: Pretty Good Privacy (Asymmetric Encryption Key Pair, where public key is used to encrypt, private key used to decrypt)
* **SOPS**: "Secret Operations" CLI tool by Mozilla, leverages KMS or PGP to encrypt secrets in a Git Repo. (Flux and P1's modified ArgoCD can use SOPS to decrypt secrets stored in a Git Repo.)
* **ATO**: Authority to Operate
* **cATO**: continuous Authority to Operate
* **AO**: Authorizing Official (Government Official who determines OS and Kubernetes Cluster hardening requirements, that result in a level of acceptable remaining risk that they're willing to sign off on for a Kubernetes Cluster to receive an ATO, and a BigBang Cluster to receive a cATO)
* **IaC**: Infrastructure as Code
* **CaC**: Configuration as Code
* **CAC**: Common Access Card  

## Prerequisites

* Prerequisites vary depending on deployment scenario. [Prerequisites can be found here.](../prerequisites/)

## Additional Useful Background Contextual Information

* Big Bang utilizes Documents as Code stored in the main [Big Bang Repo](https://repo1.dso.mil/big-bang/bigbang/docs). For a better experience, the documentation can also be found on the [Big Bang Documentation Website](https://docs-bigbang.dso.mil).
    * All locations use the same source code and will include pointers between them.
* There are multiple implementations of Helm Charts (Helm repositories, `.tgz`, and files and folders in a git repo), whenever Platform One refers to a helm chart, it always referring to the files and folders in a git repo implementation, which is stored in the `/chart` folder within a git repo.
* Additional pre-reading materials to develop a better understanding of Big Bang before deploying can be found in this `understanding_bigbang` section.
* If you see an issue with docs or packages, please [open an issue against the main Big Bang Repo](https://repo1.dso.mil/big-bang/bigbang/-/issues), instead of the individual package repo.

## Note about Snippets of Architecture Diagrams in this folder

* The intent of sharing Architecture Diagrams is to:
    * Act as a starting point upon which further understanding can be built.
    * Improve a users understanding of how Big Bang components fit together.
    * Provide insight on what it would take to modify components or workflows to fit specific use cases.
    * Show potential use cases for some of BigBang's core components.
* These Architecture Diagrams are NOT intended to:
    * Reflect an accurate default configuration.
    * Prescriptively show the only possible solution of a Big Bang deployment
* These Architecture Diagrams should be taken with a grain of salt; it's difficult to make a generic diagram with high accuracy. Big Bang's Helm Values are variables, some values can produce significantly different workflows. Nuances specific to the deployment environment and hardened configurations like SELinux & Istio CNI can slightly effect parts of implementation details.
