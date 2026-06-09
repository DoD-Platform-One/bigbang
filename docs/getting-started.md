## Getting Started
Start here if you're new to Big Bang:
- **[Overview](what.md)**: Introduction to Big Bang concepts
- **[Customer Template](https://repo1.dso.mil/big-bang/customers/template)**: You will need to instantiate a Big Bang environment tailored to your needs. This template is provided for you to copy into your own Git repository and begin modifications.
- **[Prerequisites](getting-started/prerequisites.md)**: Cluster and environment requirements
- **[Quick Start](installation/environments/quick-start.md)**: Deploy Big Bang in minutes
- **[First Deployment](https://repo1.dso.mil/big-bang/customers/template)**: A customer template with a step-by-step deployment walkthrough
- **[FAQ](getting-started/faq.md)**: Common questions and answers

Additionally, several useful starting points in the Big Bang documentation are listed in the following:

- **[Developer Contribution Documentation](./community/development/index.md)**
- **[Key Big Bang Concept Overviews](./concepts/index.md)**
- **[Tutorials for Big Bang](./tutorials/)**
- **[Big Bang Example Configurations](https://repo1.dso.mil/big-bang/bigbang/-/tree/master/docs/reference/configs/example)**
## How do I deploy Big Bang?

**Note:** The Deployment Process and Pre-Requisites will vary depending on the deployment scenario. The [Quick Start Demo Deployment](../installation/environments/quick-start.md) for example, allows some steps to be skipped due to a mixture of automation and generically reusable demonstration configuration that satisfies pre-requisites. The following is a general overview of the process, reference the [deployment guides](../installation/index.md) for more detail.

1. Satisfy Pre-Requisites:
    * Provision a Kubernetes Cluster according to [best practices](./prerequisites.md#kubernetes-cluster).
    * Ensure the cluster has network connectivity to a Git Repo you control.
    * Install Flux GitOps Operator on the cluster.
    * Configure Flux, the cluster, and the Git Repo for GitOps Deployments that support deploying encrypted values.
    * Commit to the Git Repo Big Bang's `values.yaml` and encrypted secrets that have been configured to match the desired state of the cluster (including HTTPS Certs and DNS names).
1. `kubectl apply --filename bigbang.yaml`
    * [bigbang.yaml](https://repo1.dso.mil/big-bang/customers/template/-/blob/main/helmRepo/dev/bigbang.yaml) will trigger a chain reaction of GitOps Custom Resources that will deploy other GitOps Custom Resources that will eventually deploy an instance of a DevSecOps Platform that's declaratively defined in your Git Repo.
    * To be specific, the chain reaction pattern we consider best practice is to have:
        * `bigbang.yaml` deploys a git repository and kustomization Custom Resource.
        * Flux reads the declarative configuration stored in the kustomization Custom Resource to do a GitOps equivalent of `kustomize build . | kubectl apply  --filename -`, to deploy a helmrelease Custom Resource of the Big Bang Helm Chart, that references input `values.yaml` files defined in the Git Repo.
        * Flux reads the declarative configuration stored in the helmrelease Custom Resource to do a GitOps equivalent of `helm upgrade --install bigbang /chart  --namespace=bigbang  --filename encrypted_values.yaml --filename values.yaml --create-namespace=true`, the Big Bang Helm Chart, then deploys more Custom Resources that flux uses to deploy packages specified in Big Bang's `values.yaml.`
### Additional Installation and Configuration Guides

- **[Installation](installation/)**: Environment-specific deployment guides
- **[Configuration](configuration/)**: Customization options and best practices
- **[Big Bang Example Configurations](https://repo1.dso.mil/big-bang/bigbang/-/tree/master/docs/reference/configs/example)**: Example configurations yaml files for Big Bang
- **[Migration](migration/)**: Upgrade and migration procedures

## New User Orientation

New users are encouraged to read through the useful background information present in the [Getting Started](../docs/getting-started/), [Concepts](../docs/concepts/), [Configuration](../docs/configuration/), and [Packages](../docs/packages/) sections.
