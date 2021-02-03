# Package Requirements

All Big Bang Packages shall adhere to the following requirements.  Where possible, each package shall validate these requirements in their CI/CD processes

[[_TOC_]]

## PR-X. Kubernetes Cluster Requirements

Each package will work with any cluster under the following criteria.

* Kubernetes Versions "Latest -2".  Current latest is 1.20, so also supports 1.19 and 1.18.
* [Cloud Native Computing Federation Kubernetes Certified Distribution](https://www.cncf.io/certification/software-conformance/).
* Default Storage Class with RWO

## PR-X. Iron Bank Images

Every Big Bang Package shall be configured to use exclusively Iron Bank approved images.

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

## PR-X. Package Versioning Scheme

Big Bang packages follow a standard semantic versioning scheme for both the package tag and the chart version.  The package tag will always be in line with the chart version (not the `appVersion`).  To distinguish between BigBang specific changes within the semantic version of the upstream chart, a suffix of `-bb.#` will be added to _all_ charts and tags.

For example, for the upstream [`istio-operator`](https://github.com/istio/istio/tree/1.7.3/manifests/charts/istio-operator) pinned at version `1.7.3`, the big bang version (with the modified `values.yaml` for an Iron Bank image) will be tagged `1.7.3-bb.0`.  If in the same `istio-operator` release, BigBang requires chart modifications (such as to support `imagePullSecrets`), then the new version becomes `1.7.3-bb.1`.

For another example in using the [`kube-prometheus-stack`](https://github.com/prometheus-community/helm-charts/tree/kube-prometheus-stack-12.2.2/charts/kube-prometheus-stack), the upstream is versioned at `12.2.2`, meaning BigBang's initial fork will be `12.2.2-bb.0`.  Future additions, such as adding `VirtualServices` for the ingresses, bumps to the `-bb.#` will happen in sequence every time BigBang updates the chart within the same version.

## PR-X. Package Standards

The common components that each package will have are defined in the following folder layout:

```bash
├── CODEOWNERS              # GitLab Code Owners for Package Owners/Understudies.
├── README.md               # top level summary of package
├── docs/                   # detailed documentation folder describing package consumption details and assumptions
├── tests/
    ├── cypress             # folder containing e2e tests using the cypress test framework
├── chart/                  # Folder containing helm chart
```

## PR-X. CI/CD pipeline is required for each Big Bang Package

Each package shall contain a .gitlab-ci.yml file at the top of the package repo.   This file shall reference the pipeline CI/CD infrastructure
files and include the following contents:

```bash
include:
  - project: 'platform-one/big-bang/pipeline-templates/pipeline-templates'
    ref: master
    file: '/templates/package-tests.yaml'
```

## PR-X. Dependencies must be Big Bang Package

If a Package has a dependency on another Package to function, the dependency shall also be a Big Bang Package

## PR-X. Dependency Matrix

Each Package will clearly articulate in documentation any dependent Big Bang Package and versions.

## PR-X Kubernetes Component Requirements

These requirements for the kubernetes components come from the Kubernetes STIG, Kubesec.io and other best practices

* Resource Limits and Requests set for cpu and memory and they are [Guaranteed QoS](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/#create-a-pod-that-gets-assigned-a-qos-class-of-guaranteed)
* Containers are not run in privileged mode
* Read Only Root File System is set to true
* Containers are not run as root
* runAsUser > 1000
* Each deployment/daemonset/statefulset should use its own service account with least privilege permission set
* HostPath volumes are not allowed
* All resources contain the [Kubernetes Common Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/)
* All containers contain health and liveness checks

## Branching

Each package will have a default branch of `main`.  Immutable tags will be used to identify releases and will follow a semver versioning scheme.  For more information, see the [versioning](#pr-x.-package-versioning-scheme) section.

## Package Standards

* Helm Packages contain one kubernetes object definition
* Helm charts should have the flexibility to enable istio and defaults to disable

```yaml
   istio:
     enabled: false
```

* Helm charts should have the flexibility to enable service monitors and defaults to disable

```yaml
   monitoring:
     enabled: false
```

* Helm charts should have the flexibility to enable keycloak and defaults to disable
* Helm dependency manage charts dependencies in Chart.yaml and the dependency chart can be enabled or disabled using condition.
* All Chart names are lower case letters and numbers, separated with dashes. No dots, uppercase or underscores.
* Helm Chart values variable names should begin with a lowercase letter and words should be separated with Camel case
* Helm chart dependency version,use version ranges instead of pinning to an exact version.
    version: ~1.2.3
* There should be a Helm values file located at `tests/test-values.yaml` used for pipeline testing.
