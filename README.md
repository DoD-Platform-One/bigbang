# Big Bang

Big Bang is a declarative, continuous delivery tool for deploying Department of Defense (DoD) hardened and approved packages into a Kubernetes cluster.

> If viewing this from Github, note that this is a mirror of a government repo hosted on [Repo1](https://repo1.dso.mil/) by [DoD Platform One](http://p1.dso.mil/).  Please direct all code changes, issues and comments to [https://repo1.dso.mil/big-bang/bigbang](https://repo1.dso.mil/big-bang/bigbang)

## Usage & Scope

Big Bang's scope is to provide publicly available installation manifests for packages required to adhere to the DoD DevSecOps Reference Architecture and additional useful utilities. Big Bang packages are broken into three categories:

- **Core:** [Core packages](./docs/understanding-bigbang/package-architecture/README.md#core) are a group of capabilities required by the DoD DevSecOps Reference Architecture, that are supported directly by the Big Bang development team. The specific capabilities that are considered core currently are Service Mesh, Policy Enforcement, Logging, Monitoring, and Runtime Security.

- **Add-ons:** [Addon packages](./docs/understanding-bigbang/package-architecture/README.md#addons) are any packages/capabilities that the Big Bang development team directly supports that do not fall under the above core definition. These serve to extend the functionality/features of Big Bang.

- **Community:** [Community packages](https://repo1.dso.mil/big-bang/product/community) are any packages that are maintained by the broader Big Bang community (e.g., users and/or vendors). These packages could be alternatives to core or add-on packages, or even entirely new packages to help extend usage/functionality of Big Bang.

In order for an installation of Big Bang to be a valid installation/configuration, you must install/deploy a core package of each category. For additional details on categories and options, see [here](./docs/understanding-bigbang/package-architecture/README.md##Core).

Big Bang also builds tooling around the testing and validation of Big Bang packages. These tools are provided as-is, without support.

Big Bang is intended to be used for deploying and maintaining a DoD hardened and approved set of packages into a Kubernetes cluster.  Deployment and configuration of ingress/egress, load balancing, policy auditing, logging, and/or monitoring are handled via Big Bang.  Additional packages (e.g., ArgoCD and GitLab) can also be enabled and customized to extend Big Bang's baseline.  Once deployed, the Kubernetes cluster can be used to add mission specific applications.

Additional information can be found in the [Big Bang Docs](./docs/README.md).

## Getting Started

- You will need to instantiate a Big Bang environment tailored to your needs.  [The Big Bang customer template](https://repo1.dso.mil/big-bang/customers/template) is provided for you to copy into your own Git repository and begin modifications.
- There is a [Quick Start guide](https://repo1.dso.mil/big-bang/bigbang/-/blob/master/docs/guides/deployment-scenarios/quickstart.md) to be used as an example deployment scenario.

## Contributing to Big Bang

There are three primary ways to contribute to Big Bang. They are listed in the following:

- [Contribute to the Big Bang Team's Backlog](https://repo1.dso.mil/big-bang/bigbang/-/issues).
- [Contribute to open-source projects under the Big Bang Technical Oversight Committee (BBTOC)](https://repo1.dso.mil/big-bang/product/bbtoc/-/blob/master/CONTRIBUTING.md).
- [Submit new package proposals](https://repo1.dso.mil/big-bang/product/bbtoc/-/issues/new?issue%5Bmilestone_id%5D=).
  - Please review the [package integration guide](./docs/developer/package-integration/README.md) if you are interested in submitting a new package.
  - A shepherd will be assigned to the project to create a repo in the [Big Bang Community Packages](https://repo1.dso.mil/big-bang/product/community).

Additional information can be found in the [contributing guide](./CONTRIBUTING.md).

## Release Schedule

- Big Bang releases adopt a standardized versioning based on and loosely following the [Semantic Versioning 2.0.0 guidelines](https://semver.org/spec/v2.0.0.html) (major.minor.patch). These releases are not based on a fixed schedule and instead, follow the specifics in the scheme that is described in this section. 

### Patch Version

A patch version increment is performed when there is a change in the tag (i.e., version number) of a Big Bang core package or a bug fix for a Big Bang template or values files. A change in the patch version number should be backwards compatible with previous patch changes within a minor version. If there is a significant functionality change in the a core package that requires adjustments to Big Bang templates, this would require a change in the minor or major version depending on the impact to the values and secrets used to integrated the package with Big Bang.

NOTE: Patch versions would not typically be created for addon package updates, rather customers would be expected to be updating those packages via `git.tag`/`helmRepo.tag` changes directly, or "inheriting" those updates through another version.

### Minor Version

A minor version increment is required when there is a change in the integration of Big Bang with core or addon packages. For example, the following changes warrant a Minor version change:

- Change in the umbrella values.yaml (except for changes to package version keys)
- Change in any Big Bang templates (non bug fix changes)

Minor version changes should be backwards compatible.

### Major Version

A major version increment indicates a release that has significant changes, which could potentially break compatibility with previous versions. A major change is required when there are changes to the architecture of Big Bang or critical values file keys. For example removing a core package or changing significant values that propagate to all core and add-on packages are considered major version changes. Examples of major version changes are provided in the folowing:

- Removal or renaming of Big Bang values.yaml top level keys (e.g., istio and/or git repository values).
- Change to the structure of chart/templates files or key values.
- Additional integration between core/add-on packages that require change to the charts of all packages.
- Modification of Big Bang GitOps engine (i.e., switching from FluxCD -> ArgoCD).

To see what is on the roadmap or included in a given release you can still review our [project milestones](https://repo1.dso.mil/groups/big-bang/-/milestones).

## Community

The Big Bang Universe Community Slack workspace is a great place to go to get involved, interact with the community, and ask for help. You can join the workspace with [this invite link](https://join.slack.com/t/bigbanguniver-ft39451/shared_invite/zt-21zrvwacw-zoionTAz0UdzVbjnAFSnDw).

## Navigating our Documentation

> All Big Bang documentation is also provided at [https://docs-bigbang.dso.mil](https://docs-bigbang.dso.mil) offering a better experience and improved searchability.

Several useful starting points in the Big Bang documentation are listed in the following:

- [Developer Contribution Documentation](./docs/developer/README.md)
- [Key Big Bang Concept Overviews](./docs/understanding-bigbang/README.md)
- [User Guides for Big Bang](./docs/guides/README.md)
- [Big Bang Prerequisites](./docs/prerequisites/README.md)
- [Big Bang Example Configurations](https://repo1.dso.mil/big-bang/bigbang/-/tree/master/docs/assets/configs/example)
