# BigBang Docs

## What is BigBang?

* BigBang is a Helm Chart that is used to deploy a DevSecOps Platform on a Kubernetes Cluster. The DevSecOps Platform is composed of application packages which are bundled as helm charts that leverage IronBank hardened container images.
* The BigBang Helm Chart deploys gitrepository and helmrelease Custom Resources to a Kubernetes Cluster that's running the Flux GitOps Operator, these can be seen using `kubectl get gitrepository,helmrelease -n=bigbang`. Flux then installs the helm charts defined by the Custom Resources into the cluster.
* The BigBang Helm Chart has a values.yaml file that does 2 main things:
  1. Defines which DevSecOps Platform packages/helm charts will be deployed
  2. Defines what input parameters will be passed through to the chosen helm charts.
* You can see what applications are part of the platform by checking the following resources:
  * [../Packages.md](../Packages.md) lists the packages and organizes them in categories. 
  * [Release Notes](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/releases) lists the packages and their versions.
  * For a code based source of truth, you can check [BigBang's default values.yaml](../chart/values.yaml), and `[CTRL] + [F]` "repo:", to quickly iterate through the list of applications supported by the BigBang team. 

## How do I deploy BigBang?

**Note:** The Deployment Process and Pre-Requisites will vary depending on the deployment scenario. The [Quick Start Demo Deployment](guides/deployment_scenarios/quickstart.md) for example, allows some steps to be skipped due to a mixture of automation and generically reusable demo configuration that satisfies pre-requisites.
The following is a general overview of the process, the [deployment guides](guides/deployment_scenarios) go into more detail.

1. Satisfy Pre-Requisites:
   * Provision a Kubernetes Cluster according to [best practices](guides/prerequisites/kubernetes_preconfiguration.md#best-practices).
   * Ensure the Cluster has network connectivity to a Git Repo you control.
   * Install Flux GitOps Operator on the Cluster.
   * Configure Flux, the Cluster, and the Git Repo for GitOps Deployments that support deploying encrypted values.
   * Commit to the Git Repo BigBang's values.yaml and encrypted secrets that have been configured to match the desired state of the cluster (including HTTPS Certs and DNS names).  
2. `kubectl apply --filename bigbang.yaml`
   * [bigbang.yaml](https://repo1.dso.mil/platform-one/big-bang/customers/template/-/blob/main/dev/bigbang.yaml) will trigger a chain reaction of GitOps Custom Resources' that will deploy other GitOps CR's that will eventually deploy an instance of a DevSecOps Platform that's declaratively defined in your Git Repo.
   * To be specific, the chain reaction pattern we consider best practice is to have:
     * bigbang.yaml deploys a gitrepository and kustomization Custom Resource
     * Flux reads the declarative configuration stored in the kustomization CR to do a GitOps equivalent of `kustomize build . | kubectl apply  --filename -`, to deploy a helmrelease CR of the BigBang Helm Chart, that references input values.yaml files defined in the Git Repo.
     * Flux reads the declarative configuration stored in the helmrelease CR to do a GitOps equivalent of `helm upgrade --install bigbang /chart  --namespace=bigbang  --filename encrypted_values.yaml --filename values.yaml --create-namespace=true`, the BigBang Helm Chart, then deploys more CR's that flux uses to deploy packages specified in BigBang's values.yaml
  
## New User Orientation

* New users are encouraged to read through the Useful Background Contextual Information present in the [understanding_bigbang folder](./understanding_bigbang)
