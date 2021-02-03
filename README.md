# Big Bang

Big Bang is a declarative, continuous delivery tool for core DoD hardened and approved [packages](#packages) into a Kubernetes cluster.  Big Bang follows a [GitOps](#gitops) approach to configuration management, using [Flux v2](#flux-v2) to reconcile Git with the cluster.  Environments (e.g. dev, prod) and packages (e.g. istio) can be fully configured to suit the deployment needs.

## Usage

Big Bang is intended to be used for deploying and maintaining a DoD hardened and approved set of packages into a Kubernetes cluster.  Deployment and configuration of ingress/egress, load balancing, policy auditing, logging, monitoring, etc. are handled via Big Bang.   Additional packages (e.g. ArgoCD, GitLab) can also be enabled and customized to extend Big Bang's baseline.  Once deployed, the customer can use the Kubernetes cluster to add mission specific applications.

Additional information can be found in [Big Bang Overview](./docs/1_overview.md).

## Getting Started

To start using Big Bang, you will need to create your own Big Bang environment tailored to your needs.  The [Big Bang customer template](https://repo1.dso.mil/platform-one/big-bang/customers/template/) is provided for you to copy into your own Git repository and begin modifications.  Follow the instructions in [Big Bang Getting Started](./docs/2_getting_started.md) to customize and deploy Big Bang.

### Contributing

Please see the [contributing guide](./CONTRIBUTING.md) if you are interested in contributing to Big Bang.
