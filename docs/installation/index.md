# Installation

This section provides guidance for installing Big Bang in various environments. Whether you're setting up a new cluster or migrating from an existing deployment, these documents will guide you through the installation process and help you avoid common pitfalls.

## What You'll Find Here

The installation documentation covers the essential aspects of deploying Big Bang:

- **Prerequisites**: Cluster requirements, infrastructure setup, and dependency verification
- **Installation Methods**: Step-by-step installation procedures for different environments
- **Configuration**: Essential configuration options and customization guidance
- **Validation**: Post-installation verification and health checks

## Installation Overview

Big Bang uses GitOps principles with Flux to deploy and manage Kubernetes applications. The installation process typically involves:

1. **Cluster Preparation**: Ensuring your Kubernetes cluster meets Big Bang requirements
2. **Flux Installation**: Setting up the GitOps engine that manages deployments
3. **Big Bang Deployment**: Configuring and deploying the Big Bang umbrella chart
4. **Package Configuration**: Customizing individual packages for your environment
5. **Validation**: Verifying successful deployment and functionality

## Quick Start

For a basic installation:

1. Verify cluster meets [prerequisites](#prerequisites)
2. Install Flux controllers
3. Deploy Big Bang with your configuration
4. Validate installation using the health checks

## Prerequisites

Before installing Big Bang, ensure your environment meets these requirements:

- **Kubernetes Version**: Compatible Kubernetes cluster (see compatibility matrix)
- **Node Resources**: Sufficient CPU, memory, and storage capacity
- **Network Access**: Connectivity to required registries and repositories
- **Storage Classes**: Available persistent storage for applications
- **Load Balancer**: External load balancer capability (cloud or on-premises)

See the [detailed prerequisites guide](../getting-started/prerequisites.md) for more information.

## Common Installation Scenarios

Big Bang supports various deployment patterns:

- **Cloud Deployments**: AWS EKS in GovCloud
- **On-Premises**: Self-managed Kubernetes clusters
- **Edge Deployments**: Resource-constrained environments 
- **Air-Gapped**: Disconnected environments with registry mirrors

**[Note: While we are compatible with air-gapped and edge deployments, we do not validate them.]**

## How do I deploy Big Bang?

>**Note:** The deployment process and prerequisites vary depending on your deployment
scenario. The [Quick Start Demo](https://repo1.dso.mil/big-bang/bigbang/-/blob/installation/environments/quick-start.md) Deployment
automates several steps using reusable demo configuration. For a production reference,
see the [Big Bang customer template](https://repo1.dso.mil/big-bang/customers/template).
The following is a general overview - refer to the [deployment guides](https://repo1.dso.mil/big-bang/bigbang/-/blob/installation/index.md)
for environment-specific detail.
---
### Step 1 - Obtain Registry1 Credentials

All Big Bang container images are sourced from [Iron Bank](https://p1.dso.mil/products/iron-bank)
via `registry1.dso.mil`. A Registry1 account with a valid image pull token is required
before anything in Big Bang can run - including Flux itself. You can request credentials from Iron Bank [here](https://repo1.dso.mil/dsop/big-bang/base/-/work_items/new?initialCreationContext=list-route&type=ISSUE&description_template=Robot%20Account).

>In production, use robot credentials rather than personal tokens:
`robot$bigbang-onboarding-imagepull`

For air-gapped environments, all required images are bundled in the
[Big Bang release artifacts](https://repo1.dso.mil/big-bang/bigbang/-/releases) as
`images.tar.gz`. See the air-gap [deployment guide](https://repo1.dso.mil/big-bang/bigbang/-/blob/installation/environments/airgap.md)
for full instructions. [Zarf](https://repo1.dso.mil/big-bang/bigbang/-/blob/installation/environments/airgap-zarf.md) is the
recommended tooling for air-gapped deployments. 

**[Note: These documents are currently out of date and under review.]**

---
### Step 2 - Prepare Your Infrastructure
Big Bang assumes **bring-your-own cluster (BYOC)**. The cluster itself is not provisioned by
Big Bang. Before deploying, ensure the following requirements are met.

**Hardware (minimum per node)**

| Resource | Minimum |
|---|----|
|CPU|4 cores|
|Memory|16GB|
|Disk|100GB|
|Nodes|3 (distributed across availability zones for HA)|

Deploying additional packages increases resource requirements. Refer to each package's
`values.yaml` for its specific resource requests and limits.

**Kubernetes Cluster Requirements**
- **A non-EOL Kubernetes version:** See `kubeVersion` in `Chart.yaml` for the supported range
- **A CNI that supports NetworkPolicies:** `flannel` does not support NetworkPolicies and is
not suitable for production Big Bang deployments
- **A default StorageClass with dynamic volume provisioning:** For production, a StorageClass
supporting `ReadWriteMany` access mode is recommended for HA add-on configurations
- **Load balancer support - one of:**
  - CSP-managed load balancers (AWS EKS, Azure AKS, GKE) via cloud provider integration
  - MetalLB, kube-vip, or
  kube-router for bare metal
  - `NodePort` override if no load balancer provisioner is available
---
### Step 3 - Set Up Your Git Repository
Big Bang's desired state is declared entirely in Git. Before bootstrapping:
- Provision a Git repository you control with network connectivity to the cluster
- Commit Big Bang's `values.yaml` configured for your environment - including DNS names,
HTTPS certificates, enabled packages, and registry credentials
- Encrypt secrets using https://github.com/mozilla/sops and commit encrypted
values alongside your configuration

A reference repository structure is available in the
https://repo1.dso.mil/big-bang/customers/template.

---
### Step 4 Install Flux
Flux is Big Bang's GitOps engine. Always install Flux using the bootstrap manifests that
ship with the specific Big Bang version you are deploying - this ensures compatibility.
````
export REGISTRY1_USER='your-registry1-username'
export REGISTRY1_TOKEN='your-registry1-token'
export BB_VERSION='3.21.0'   # pin to your target BB release version

kubectl create ns flux-system

kubectl create secret docker-registry private-registry \
--docker-server=registry1.dso.mil \
--docker-username=$REGISTRY1_USER \
--docker-password=$REGISTRY1_TOKEN \
--namespace flux-system

kubectl apply -k https://repo1.dso.mil/big-bang/bigbang.git//base/flux?ref=${BB_VERSION}
````
Alternatively, use the install script included in the Big Bang repository:
````
git clone https://repo1.dso.mil/big-bang/bigbang.git
./bigbang/scripts/install_flux.sh -u $REGISTRY1_USER -p $REGISTRY1_TOKEN
````
Verify Flux is running before proceeding:
````
kubectl get pods -n flux-system
kubectl get crds | grep flux
````
>**Note:** Always pin Flux installation to the base/flux ref matching your target Big Bang version. Do not use master in production.
---
### Step 5 - Deploy Big Bang
With Flux running and your Git repository configured, bootstrap Big Bang with a single
command:
````
kubectl apply --filename bigbang.yaml
````
A reference `bigbang.yaml` is available in the
https://repo1.dso.mil/big-bang/customers/template/-/blob/main/helmRepo/dev/bigbang.yaml.

This triggers a GitOps chain reaction that fully bootstraps the platform:
1. `bigbang.yaml` creates a `GitRepository` and `Kustomization` Custom Resource in the
cluster.
2. Flux reads the `Kustomization` and performs the equivalent of:
````
kustomize build . | kubectl apply --filename -
````
3. This deploys a `HelmRelease` Custom Resource for the Big Bang Helm Chart, referencing
   your `values.yaml` files stored in Git.
4. Flux reads the HelmRelease and performs the equivalent of:
````
   helm upgrade --install bigbang ./chart \
   --namespace bigbang \
   --values encrypted_values.yaml \
   --values values.yaml \
   --create-namespace
````
5. The Big Bang Helm Chart deploys additional `GitRepository`, `HelmRepository`, and
   `HelmRelease` Custom Resources - one per enabled package. Flux reconciles each
   independently, deploying the full DevSecOps platform as declared in your Git repository.
---
### Step 6 - Validate
Monitor the rollout until all resources converge:
````
# Watch all Flux-managed resources reconcile
watch kubectl get gitrepositories,kustomizations,helmreleases,pods -A

# Check for any pods not in Running or Completed state
kubectl get pods -A | grep -Ev 'Running|Completed'
````
All `HelmRelease` resources should reach `Ready: True`. Packages may take several minutes to reconcile depending on cluster resources and image pull times.


## New User Orientation

New users are encouraged to read through the useful background information present in the [Getting Started](../getting-started/), [Concepts](../concepts/), [Configuration](../configuration/), and [Packages](../packages/) sections.


## When Installation Problems Occur

Installation issues can manifest at different stages of the deployment process. Our [troubleshooting documentation](../operations/troubleshooting/index.md) is organized to help you quickly identify and resolve problems based on the symptoms you're experiencing:

### Diagnostic Approach

When facing installation problems, follow this systematic approach:

1. **Start with Installation Troubleshooting** for immediate deployment failures
2. **Move to Package Troubleshooting** for individual component issues
3. **Check Networking Troubleshooting** for connectivity problems
4. **Use Performance Troubleshooting** for resource-related issues

Each guide provides both quick diagnostic commands and detailed remediation steps, allowing you to either quickly resolve common issues or dive deep into complex problems.

## Post-Installation Operations

After successful installation, transition to operational procedures:

1. **Set Up Monitoring**: Configure observability using [Operations Monitoring](../operations/monitoring.md)
2. **Plan Backups**: Implement backup strategies from [Operations Backup & Restore](../operations/backup-restore.md)
3. **Review Upgrades**: Understand upgrade procedures in [Operations Upgrades](../operations/upgrades.md)
4. **Ongoing Maintenance**: Follow guidance in [Operations Maintenance](../operations/maintenance/)

## Getting Help

If troubleshooting guides don't resolve your issue:

- Gather diagnostic information using commands from the troubleshooting guides
- Check Big Bang GitLab repository for similar reported issues
- Engage with the Big Bang community with detailed problem descriptions
- Consider escalating to platform support with collected diagnostic data

The troubleshooting documentation is designed to provide both immediate solutions and the diagnostic information needed for effective support requests.
