# Big Bang

Big Bang is a declarative, continuous delivery tool for deploying DoD hardened and approved packages into a Kubernetes cluster.

> _If viewing this from Github, note that this is a mirror of a government repo hosted on [Repo1](https://repo1.dso.mil/) by [DoD Platform One](http://p1.dso.mil/).  Please direct all code changes, issues and comments to [https://repo1.dso.mil/platform-one/big-bang/bigbang](https://repo1.dso.mil/platform-one/big-bang/bigbang)_

## Usage & Scope

Big Bang's scope is to provide publicly available installation manifests for packages required to adhere to the DoD DevSecOps Reference Architecture and additional useful utilities. Big Bang packages are broken into three categories:

- Core: [Core packages](./docs/understanding-bigbang/package-architecture/README.md##Core) are a group of capabilities required by the DoD DevSecOps Reference Architecture, that are supported directly by the Big Bang development team. The specific capabilities that are considered core currently are Service Mesh, Policy Enforcement, Logging, Monitoring, and Runtime Security.

- Addons: [Addon packages](./docs/understanding-bigbang/package-architecture/README.md##Addons) are any packages/capabilities that the Big Bang development team directly supports that do not fall under the above core definition. These serve to extend the functionality/features of Big Bang.

- Community: [Community packages](https://repo1.dso.mil/big-bang/product/community) are any packages that are maintained by the broader Big Bang community (users, vendors, etc). These packages could be alternatives to core or addon packages, or even entirely new packages to help extend usage/functionality of Big Bang.

In order for an installation of Big Bang to be a valid installation/configuration you must install/deploy a core package of each category (for additional details on categories and options see [here](./docs/understanding-bigbang/package-architecture/README.md##Core)).

Big Bang also builds tooling around the testing and validation of Big Bang packages. These tools are provided as-is, without support.

Big Bang is intended to be used for deploying and maintaining a DoD hardened and approved set of packages into a Kubernetes cluster.  Deployment and configuration of ingress/egress, load balancing, policy auditing, logging, monitoring, etc. are handled via Big Bang.  Additional packages (e.g. ArgoCD, GitLab) can also be enabled and customized to extend Big Bang's baseline.  Once deployed, the Kubernetes cluster can be used to add mission specific applications.

Additional information can be found at [Big Bang Docs](https://docs-bigbang.dso.mil) and [here](./docs/README.md).

## Getting Started

- You will need to instantiate a Big Bang environment tailored to your needs.  [The Big Bang customer template](https://repo1.dso.mil/platform-one/big-bang/customers/template/) is provided for you to copy into your own Git repository and begin modifications.

## Contributing to Big Bang

There are 3 main ways to contribute to Big Bang:

- [Contribute to the Big Bang Team's Backlog](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues)
- [Contribute to open-source projects under the Big Bang Technical Oversight Committee (BBTOC)](https://repo1.dso.mil/platform-one/bbtoc/-/blob/master/CONTRIBUTING.md)
- [Submit new package proposals](https://repo1.dso.mil/platform-one/bbtoc/-/issues/new?issue%5Bmilestone_id%5D=)
  - Please review the [package integration guide](./docs/developer/package-integration/README.md) if you are interested in submitting a new package
  - A shepherd will be assigned to the project to create a repo in the [BB sandbox](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox)

Additional information can be found in the [contributing guide](./CONTRIBUTING.md).

## Release Schedule

- Big Bang releases every 2 weeks with a minor release number. In order to stay current with all features and security updates ensure you are no more than `n-2` releases behind.
  - To see what is on the roadmap please see our [project milestones](https://repo1.dso.mil/groups/platform-one/big-bang/-/milestones)

## Navigating our documentation

Big Bang Documentation is located in the following locations:

- [Developer Contribution Documentation](./docs/developer/README.md)
- [Key Big Bang Concept Overviews](./docs/understanding-bigbang/README.md)
- [User Guides for Big Bang](./docs/guides/README.md)
- [Big Bang Prerequisites](./docs/prerequisites/README.md)
- [Big Bang Example Configurations](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/tree/master/docs/assets/configs/example/)
