# Big Bang

Big Bang is a declarative, continuous delivery tool for deploying DoD hardened and approved packages into a Kubernetes cluster.

> _If viewing this from Github, note that this is a mirror of a government repo hosted on [Repo1](https://repo1.dso.mil/) by [DoD Platform One](http://p1.dso.mil/).  Please direct all code changes, issues and comments to https://repo1.dso.mil/platform-one/big-bang/bigbang_

## Usage & Scope

Big Bang's scope is to provide publicly available installation manifests for:

- A specific set of packages that adhere to the DevSecOps Reference Architecture. The core list of packages can be found [here](https://repo1.dso.mil/platform-one/big-bang/apps/core). 

- Packages that facilitate development of applications that adhere to the DevSecOps Reference Architecture. The full list of packages can be found [here](https://repo1.dso.mil/platform-one/big-bang/apps). 

Big Bang also builds tooling around the testing and validation of Big Bang packages. These tools are provided as-is, without support.

Big Bang is intended to be used for deploying and maintaining a DoD hardened and approved set of packages into a Kubernetes cluster.  Deployment and configuration of ingress/egress, load balancing, policy auditing, logging, monitoring, etc. are handled via Big Bang.   Additional packages (e.g. ArgoCD, GitLab) can also be enabled and customized to extend Big Bang's baseline.  Once deployed, the customer can use the Kubernetes cluster to add mission specific applications.

Additional information can be found in [Big Bang Docs](./docs/README.md).


## Getting Started

- You will need to instantiate a Big Bang environment tailored to your needs.  [The Big Bang customer template](https://repo1.dso.mil/platform-one/big-bang/customers/template/) is provided for you to copy into your own Git repository and begin modifications.

## Contributing to Big Bang

There are 3 main ways to contribute to Big Bang: 
- [Submit new package proposals](https://repo1.dso.mil/platform-one/bbtoc/-/issues/new?issue%5Bmilestone_id%5D=)
  - Please review the [package integration guide](./docs/developer/package-integration/README.md) if you are interested in submitting a new package
  - A shepherd will be assigned to the project to create a repo in the [BB sandbox](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox)
- [Contribute to open-source projects under the Big Bang Technical Oversight Committee (bbtoc)](https://repo1.dso.mil/platform-one/bbtoc/-/blob/master/CONTRIBUTING.md)
- [Contribute to the Big Bang Team's Backlog](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues)

## Release Schedule
- Big Bang releases every 2 weeks. In order to stay current with all features and security updates ensure you are no more than `n-2` releases behind. 
  - To see what is on the roadmap please see our [project milestones](https://repo1.dso.mil/groups/platform-one/big-bang/-/milestones)

## Navigating our documentation

Big Bang Documentation is located in the following locations: 

- [Developer Contribution Documentation](./docs/developer)
- [Key Big Bang Concept Overviews](./docs/understanding-bigbang)
- [User Guides for Big Bang](./docs/guides/)
- [Big Bang Prerequisites](./docs/prerequisites/)
- [Big Bang Example Configurations](./docs/assets/configs/example/)