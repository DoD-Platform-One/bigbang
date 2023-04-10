# BigBang Docs

## What is BigBang?

* BigBang is a Helm Chart that is used to deploy a DevSecOps Platform on a Kubernetes Cluster. The DevSecOps Platform is composed of application packages which are bundled as helm charts that leverage IronBank hardened container images.
* The BigBang Helm Chart deploys gitrepository and helmrelease Custom Resources to a Kubernetes Cluster that's running the Flux GitOps Operator, these can be seen using `kubectl get gitrepository,helmrelease -n=bigbang`. Flux then installs the helm charts defined by the Custom Resources into the cluster.
* The BigBang Helm Chart has a values.yaml file that does 2 main things:
  1. Defines which DevSecOps Platform packages/helm charts will be deployed
  1. Defines what input parameters will be passed through to the chosen helm charts.
* You can see what applications are part of the platform by checking the following resources:
  * [packages.md](./packages.md) lists the packages and organizes them in categories.
  * [Release Notes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/releases) lists the packages and their versions.
  * For a code based source of truth, you can check [BigBang's default values.yaml](../chart/values.yaml), and `[CTRL] + [F]` "repo:", to quickly iterate through the list of applications supported by the BigBang team.


### What BigBang isn't

* BigBang by itself is not intended to be an End to End Secure Kubernetes Cluster Solution, but rather a reusable secure component/piece of a full solution.
* A Secure Kubernetes Cluster Solution, will have multiple components, that can each be swappable and in some cases considered optional depending on use case and risk tolerance:
  Example of some potential components in a full End to End Solution:
  * P1's Cloud Native Access Point to protect Ingress Traffic. (This can be swapped with an equivalent, or considered optional in an internet disconnected setup.)
  * Hardened Host OS
  * Hardened Kubernetes Cluster (BigBang assumes ByoC, Bring your own Cluster) (The BigBang team recommends consumers who are interested in a full solution, partner with Vendors of Kubernetes Distributions to satisfy the prerequisite of a Hardened Kubernetes Cluster.)
  * Hardened Applications running on the Cluster (BigBang helps solve this component)


## Value add gained by using BigBang

* Compliant with the [DoD DevSecOps Reference Architecture Design](https://dodcio.defense.gov/Portals/0/Documents/Library/DoD%20Enterprise%20DevSecOps%20Reference%20Design%20-%20CNCF%20Kubernetes%20w-DD1910_cleared_20211022.pdf)
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


## How do I deploy BigBang?

**Note:** The Deployment Process and Pre-Requisites will vary depending on the deployment scenario. The [Quick Start Demo Deployment](./guides/deployment-scenarios/quickstart.md) for example, allows some steps to be skipped due to a mixture of automation and generically reusable demo configuration that satisfies pre-requisites.
The following is a general overview of the process, the [deployment guides](./guides/deployment-scenarios) go into more detail.

1. Satisfy Pre-Requisites:
   * Provision a Kubernetes Cluster according to [best practices](./prerequisites/kubernetes-preconfiguration.md#best-practices).
   * Ensure the Cluster has network connectivity to a Git Repo you control.
   * Install Flux GitOps Operator on the Cluster.
   * Configure Flux, the Cluster, and the Git Repo for GitOps Deployments that support deploying encrypted values.
   * Commit to the Git Repo BigBang's values.yaml and encrypted secrets that have been configured to match the desired state of the cluster (including HTTPS Certs and DNS names).  
1. `kubectl apply --filename bigbang.yaml`
   * [bigbang.yaml](https://repo1.dso.mil/platform-one/big-bang/customers/template/-/blob/main/dev/bigbang.yaml) will trigger a chain reaction of GitOps Custom Resources' that will deploy other GitOps CR's that will eventually deploy an instance of a DevSecOps Platform that's declaratively defined in your Git Repo.
   * To be specific, the chain reaction pattern we consider best practice is to have:
     * bigbang.yaml deploys a gitrepository and kustomization Custom Resource
     * Flux reads the declarative configuration stored in the kustomization CR to do a GitOps equivalent of `kustomize build . | kubectl apply  --filename -`, to deploy a helmrelease CR of the BigBang Helm Chart, that references input values.yaml files defined in the Git Repo.
     * Flux reads the declarative configuration stored in the helmrelease CR to do a GitOps equivalent of `helm upgrade --install bigbang /chart  --namespace=bigbang  --filename encrypted_values.yaml --filename values.yaml --create-namespace=true`, the BigBang Helm Chart, then deploys more CR's that flux uses to deploy packages specified in BigBang's values.yaml
  
## New User Orientation

* New users are encouraged to read through the Useful Background Contextual Information present in the [understanding-bigbang folder](./understanding-bigbang)

## Frequently Asked Questions

You can view answers to a number of frequently asked questions [here](FAQ.md).
