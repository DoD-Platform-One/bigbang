# Package Requirements

All Big Bang Packages shall adhere to the following requirements.  Where possible, each package shall validate these requirements in their CI/CD processes

[[_TOC_]]

## Gitlab Project Settings

* The `main` branch should be default in each project
* Merge Requests should require 1 approver
* The `main` branch should be protected:
  * Developers + Maintainers should be allowed to merge.  
  * No one should be allowed to push and it should allow
  * CODEOWNERs approval should be allowed
* There should exist a protected tag with the wildcard `*-bb*`

## PR-X. Kubernetes Cluster Requirements

Each package will work with any cluster under the following criteria.

* Kubernetes Versions "Latest -2".  Current latest is 1.20, so also supports 1.19 and 1.18.
* [Cloud Native Computing Federation Kubernetes Certified Distribution](https://www.cncf.io/certification/software-conformance/).
* Default Storage Class with RWO

## PR-X. Iron Bank Images

Every Big Bang Package shall be configured to use exclusively Iron Bank approved images.  The images used __must__ be approved.

In general, the following rules must be met:

* Images must be __approved__ in IronBank
* Unmodified IronBank image must be fully functional

When the above are true, the package _may_ be considered for approval and inclusion within BigBang based off the requirements in [New Package Requests](NewPackageRequests.md).

Depending on the package, the customer need, and the approval process, packages may not comply with the above requirements to be integrated with BigBang, but still be heavily desired by customers.  To account for these packages, BigBang Third Party Packages can be used.

### Third Party Packages

[Third Party Packages](https://repo1.dso.mil/platform-one/big-bang/apps/third-party) are packages that adhere by all the BigBang package standards _except_ the IronBank containers/approvals.  These packages in many cases are still maintained by BigBang, but for security purposes are not included into the BigBang product.

[Third Party Packages](https://repo1.dso.mil/platform-one/big-bang/apps/third-party) are packages that adhere by all the BigBang package standards, but are missing key requirements (defined in [New Package Requests](NewPackageRequests.md)).  The most common being approved IronBank containers.

There are two types of third party packages:

#### Big Bang Supported and Maintained

These are packages that are supported, updated, and maintained by team members of BigBang. This designation is usually reserved for packages that key customers require, but are missing approved IronBank containers, or blanket approval that allows them to be included with the BigBang product.

These products are labeled with the "BigBang Supported" badge on the repository's `README.md` page, which indicates active support.  That being said, BigBang reserves the right to deprecate support for these packages.

#### Independent

These are packages that are not owned by team members of BigBang, but are still actively maintained independent of BigBang.  There are no rules as to who/what is allowed to own these packages, only that they must be actively maintained and up to BigBang Package Requirements.  Stale packages will be removed over time (exact timeline TBD) by members of BigBang.

## PR-X. Packages are Helm Charts

All packages that the Big Bang product consume are helm charts.  This decision is explored in depth in the ADR [here](http://about:blank).  The quick summary is that helm provides the best tools for the problem statement that Big Bang is built to address: an opinionated yet configurable deployment of the Platform One baseline.

### Helm Chart Types

Baselining off of the assumption that all packages are helm charts, we can identify _two_ different types of packages:

#### Upstream Helm Charts

Many of the tools and applications that BigBang deploys have actively maintained helm charts, rather than re-inventing the wheel, it is encouraged to leverage charts maintained by vendors or the community.  

The unfortunate downside to helm is the lack of chart customization _without_ forking from upstream.  While there are several options out there (post-rendering, etc...) that are slowly becoming more widespread, the unfortunate reality is upstream charts that BigBang consumes must be forked into repo1 and the appropriate changes must be made.

Forked upstream helm charts will be configured with the appropriate BigBang _additions_, and in rare cases, _modifications_.  They will be versioned in accordance with BigBangs [package versioning scheme](#pr-x.-package-versioning-scheme).

#### Custom Helm Charts

In the case where an accepted upstream helm chart does not exist, BigBang will create and maintain it's own custom helm chart for the package in question.  The helm chart will be in conformance with the [Package Standards](#pr-x.-package-standards).

## PR-X. Package Standards

The common components that each package will have are defined in the following folder layout:

```shell
├── CODEOWNERS              # GitLab Code Owners for Package Owners/Understudies.
├── README.md               # top level summary of package
├── docs/                   # detailed documentation folder describing package consumption details and assumptions
├── tests/
    ├── cypress             # folder containing e2e tests using the cypress test framework
├── chart/                  # Folder containing helm chart
    ├── templates           # folder helm chart templates
      ├── tests             # folder containing helm chart tests 
```

## PR-X. CI/CD pipeline is required for each Big Bang Package

Each package shall contain a .gitlab-ci.yml file at the top of the package repo.   This file shall reference the pipeline CI/CD infrastructure
files and include the following contents:

```shell
include:
  - project: 'platform-one/big-bang/pipeline-templates/pipeline-templates'
    ref: master
    file: '/templates/package-tests.yaml'
```

## PR-X. Dependencies must be Big Bang Package

If a Package has a dependency on another Package to function, the dependency shall also be a Big Bang Package

## PR-X. Dependency Matrix

Each Package will clearly articulate in documentation any dependent Big Bang Package and versions.

## Branching

Each package will have a default branch of `main`.  Immutable tags will be used to identify releases and will follow a semver versioning scheme.  For more information, see the [versioning](#pr-x.-package-versioning-scheme) section.

## Package Standards

* Helm Packages contain one kubernetes object definition

* Helm dependency manage charts dependencies in Chart.yaml and the dependency chart can be enabled or disabled using condition.
* All Chart names are lower case letters and numbers, separated with dashes. No dots, uppercase or underscores.
* Helm Chart values variable names should begin with a lowercase letter and words should be separated with Camel case
* Helm chart dependency version,use version ranges instead of pinning to an exact version.
    version: ~1.2.3
* There should be a Helm values file located at `tests/test-values.yaml` used for pipeline testing.
* Charts should support `affinity` and `nodeSelector` configuration for all components.  If there is only one type of `Pods`, then a single, top level value shall be provided, otherwise there should be `affinity` and `nodeSelector` regions for each component.  See [the Kubernetes Docs](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/) for more information
