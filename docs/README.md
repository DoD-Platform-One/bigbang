# Big Bang Documentation README

## What is Big Bang?

* Big Bang is a Helm Chart that is used to deploy a DevSecOps Platform on a Kubernetes Cluster. The DevSecOps Platform is composed of application packages which are bundled as helm charts that leverage Iron Bank hardened container images.
* The Big Bang Helm Chart deploys gitrepository and helmrelease Custom Resources to a Kubernetes Cluster running the Flux GitOps Operator, these can be seen using `kubectl get gitrepository,helmrelease -n=bigbang.` Flux then installs the helm charts defined by the Custom Resources into the cluster.
* The Big Bang Helm Chart has a values.yaml file that does two main things:
    * Defines which DevSecOps Platform packages/helm charts will be deployed.
    * Defines what input parameters will be passed through to the chosen helm charts.
* You can see what applications are part of the platform by checking the following resources:
    * [packages.md](./packages.md) lists the packages and organizes them in categories.
    * [Release Notes](https://repo1.dso.mil/big-bang/bigbang/-/releases) lists the packages and their versions.
    * For a code based source of truth, you can check [Big Bang's default values.yaml](../chart/values.yaml), and `[CTRL] + [F]`, `"repo:"`, to quickly iterate through the list of applications supported by the Big Bang team.
    * [Big Bang Universe](https://universe.bigbang.dso.mil) provides an interactive visual of all packages in Core, Addons, and Community as described in [Big Bang README](../README.md#usage--scope)

### What *isn't* Big Bang?

* Big Bang by itself is not intended to be an End-to-End Secure Kubernetes Cluster Solution, but rather a reusable secure component/piece of a full solution.
* A Secure Kubernetes Cluster Solution will have multiple components that can each be swappable and in some cases considered optional depending on use case and risk tolerance:
  Example of some potential components in a full End-to-End Solution:
    * Ingress traffic protection
        * Platform One's Cloud Native Access Point (CNAP) is one solution.
        * CNAP can be swapped with an equivalent, or considered optional in an internet disconnected setup.
    * Hardened Host OS
    * Hardened Kubernetes Cluster
        * Big Bang assumes Bring your own Cluster (BYOC)
        * The Big Bang team recommends consumers who are interested in a full solution, partner with Vendors of Kubernetes Distributions to satisfy the prerequisite of a Hardened Kubernetes Cluster.
    * Hardened Applications running on the Cluster
        * Iron Bank provides hardened containers that helps solve this component.
        * Big Bang utilizes the hardened containers in Iron Bank.

## What are the benefits of using Big Bang?

* Compliant with the [DoD DevSecOps Reference Architecture Design](https://dodcio.defense.gov/Portals/0/Documents/Library/DoD%20Enterprise%20DevSecOps%20Reference%20Design%20-%20CNCF%20Kubernetes%20w-DD1910_cleared_20211022.pdf).
* Can be used to check some but not all of the boxes needed to achieve a Continuous Authority to Operate (cATO) or Authority to Operate (ATO).
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
    * These upgrades are pre-tested. The Big Bang team "eats our own dogfood." Our CI jobs for developing the Big Bang product, run against a Big Bang Dogfood Cluster, and as part of our release process we upgrade our Big Bang Dogfood Cluster, before publishing each release.
    > **Note:** We ONLY support and recommend successive upgrades. We do not test upgrades that skip multiple minor versions.
    * Auto updates are also possible by setting kustomization.yaml to 1.x.x, because Big Bang follows semantic versioning per the [Big Bang README](../README.md#release-schedule), and flux is smart enough to read x as the most recent version number.
* SSO support is included in the Big Bang platform offering. Operations teams can leverage Big Bang's free Single Sign On capability by deploying the [Keycloak project](https://www.keycloak.org/). Using Keycloak, an ops team configures the platform SSO settings so that SSO can be leveraged by all apps hosted on the platform. For details, see the [SSO Readme](docs/developer/package-integration/sso.md). Once Authservice is configured, to enable SSO for an individual app, developers need only ensure the presence of the two following labels:
    - __Namespace__ `istio-injection=enabled`: transparently injects mTLS service mesh protection into their application's Kubernetes YAML manifest
    - __Pod__ `protect=keycloak`: declares an EnvoyFilter CustomResource to auto inject an SSO Authentication Proxy in front of the data path to get to their application

## How do I deploy Big Bang?

**Note:** The Deployment Process and Pre-Requisites will vary depending on the deployment scenario. The [Quick Start Demo Deployment](./guides/deployment-scenarios/quickstart.md) for example, allows some steps to be skipped due to a mixture of automation and generically reusable demonstration configuration that satisfies pre-requisites. The following is a general overview of the process, reference the [deployment guides](./guides/#deployment-scenarios) for more detail.

1. Satisfy Pre-Requisites:
    * Provision a Kubernetes Cluster according to [best practices](./prerequisites/kubernetes-preconfiguration.md#best-practices).
    * Ensure the cluster has network connectivity to a Git Repo you control.
    * Install Flux GitOps Operator on the cluster.
    * Configure Flux, the cluster, and the Git Repo for GitOps Deployments that support deploying encrypted values.
    * Commit to the Git Repo Big Bang's `values.yaml` and encrypted secrets that have been configured to match the desired state of the cluster (including HTTPS Certs and DNS names).  
1. `kubectl apply --filename bigbang.yaml`
    * [bigbang.yaml](https://repo1.dso.mil/big-bang/customers/template/-/blob/main/umbrella-strategy/bigbang.yaml) will trigger a chain reaction of GitOps Custom Resources that will deploy other GitOps Custom Resources that will eventually deploy an instance of a DevSecOps Platform that's declaratively defined in your Git Repo.
    * To be specific, the chain reaction pattern we consider best practice is to have:
        * `bigbang.yaml` deploys a git repository and kustomization Custom Resource.
        * Flux reads the declarative configuration stored in the kustomization Custom Resource to do a GitOps equivalent of `kustomize build . | kubectl apply  --filename -`, to deploy a helmrelease Custom Resource of the Big Bang Helm Chart, that references input `values.yaml` files defined in the Git Repo.
        * Flux reads the declarative configuration stored in the helmrelease Custom Resource to do a GitOps equivalent of `helm upgrade --install bigbang /chart  --namespace=bigbang  --filename encrypted_values.yaml --filename values.yaml --create-namespace=true`, the Big Bang Helm Chart, then deploys more Custom Resources that flux uses to deploy packages specified in Big Bang's `values.yaml.`
  
## New User Orientation

New users are encouraged to read through the useful background information present in the [Understanding Big Bang Section](./understanding-bigbang).

## Frequently Asked Questions

You can view answers to a number of [frequently asked questions](FAQ.md).

 Please direct all code changes, issues, and comments to [https://repo1.dso.mil/big-bang/bigbang](https://repo1.dso.mil/big-bang/bigbang).
