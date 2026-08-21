# Prerequisites

[[_TOC_]]

Big Bang installs and reconciles applications on an existing Kubernetes cluster. It does not provision the cluster, its networking, storage, DNS, load balancers, identity provider, or external databases.

## Resource Planning

Big Bang does not have a universal CPU, memory, disk, or node-count minimum. Capacity depends on the enabled packages, their resource requests, availability settings, retention periods, and the applications sharing the cluster.

Before an installation or upgrade:

1. Render the intended configuration and total the resource requests for all enabled packages.
2. Include application workloads, system components, persistent-data growth, and disruption headroom.
3. Confirm that affinity, topology-spread, and storage requirements can be satisfied during a node or availability-zone failure.
4. Validate the result in an environment representative of production.

The [evaluation quickstart](quick-start.md) provides workstation guidance for evaluation only; it is not a production sizing baseline.

## Kubernetes Version

The authoritative Kubernetes compatibility rule for a Big Bang release is the `kubeVersion` constraint in that release's [`chart/Chart.yaml`](../../chart/Chart.yaml). Helm evaluates this constraint during installation. A Kubernetes version is not supported merely because it is still maintained upstream.

Always review the constraint and release notes for the exact Big Bang tag being deployed. Test upgrades against the target Kubernetes and Big Bang versions before changing production.

## Cluster Capabilities

The cluster must provide:

- A conformant Kubernetes API that satisfies the chart's version constraint.
- A Container Network Interface (CNI) implementation that enforces Kubernetes `NetworkPolicy` resources.
- Working cluster DNS.
- Enough schedulable resources for the rendered requests and high-availability topology.
- A default `StorageClass` when any enabled package requests persistent storage without naming a class.
- An ingress path appropriate for the selected Istio gateway configuration.
- Access to all configured Git, Helm, OCI, image-registry, identity, and external-service endpoints.

Use the Kubernetes distribution and cloud-provider documentation to configure these capabilities. Big Bang configuration cannot compensate for a missing cluster-level network, storage, or load-balancer implementation.

### Load Balancing and Ingress

The default Istio gateway configuration creates a Kubernetes `Service` of type `LoadBalancer`. Confirm that the cluster has a supported load-balancer controller and that its address exposure matches the environment's security requirements.

For clusters without load-balancer automation, configure the Istio gateway for a supported alternative, such as a deliberately allocated `NodePort`, and connect it to infrastructure managed outside the cluster. Avoid relying on provider-specific, in-tree Kubernetes cloud integrations; use the current external cloud-controller and load-balancer guidance for the selected distribution.

### Storage

List the available classes and identify the default:

```shell
kubectl get storageclass
```

Use a Container Storage Interface (CSI) driver supported by the Kubernetes distribution and storage provider. Select classes according to each enabled package's access mode, topology, latency, expansion, snapshot, encryption, backup, and reclaim-policy requirements. In particular, do not assume that a class supporting `ReadWriteOnce` can satisfy a package's high-availability `ReadWriteMany` requirement.

Do not copy legacy examples that use in-tree provisioners such as `kubernetes.io/aws-ebs` or `kubernetes.io/azure-disk`; those plugins have been removed from current Kubernetes releases. See the upstream [StorageClass documentation](https://kubernetes.io/docs/concepts/storage/storage-classes/) and the current CSI-driver documentation for the provider.

## Node and Operating-system Requirements

Use the Kubernetes distribution's supported operating-system and node configuration. Package-specific node requirements are not global Big Bang defaults; review the upstream and package documentation for every enabled component before deployment.

Examples include Elasticsearch virtual-memory limits and SonarQube host/kernel limits. Apply such settings through the cluster's supported, persistent node-configuration mechanism and verify them after node replacement or upgrade. Do not depend on privileged init containers to change host settings unless that exception has been explicitly reviewed and approved.

For SELinux-enabled clusters, follow the current distribution and Istio CNI guidance. Do not disable SELinux or add privileged permissions as a generic workaround.

## Pod Security and Admission Control

`PodSecurityPolicy` was removed from Kubernetes in version 1.25 and is not available on Kubernetes versions supported by the current chart. Do not create, patch, or disable PSP objects as part of a Big Bang installation.

Big Bang can deploy Kyverno, Kyverno Policies, and Gatekeeper. Kubernetes also provides the built-in Pod Security Admission controller. Choose and configure admission controls deliberately, review the policies rendered by the selected Big Bang release, and document any namespace exemptions. Enabling a policy engine does not by itself guarantee a particular compliance posture.

## Distribution-specific Configuration

Set the global OpenShift switch when deploying to OpenShift:

```yaml
openshift: true
```

For all distributions, use the vendor's documentation for CNI, CSI, cloud-controller, load-balancer, SELinux, and node configuration. Avoid post-install patches copied from older Kubernetes, Istio, or distribution releases; they are not maintained as part of the Big Bang API and may weaken the cluster's security controls.

## Flux

Big Bang includes the Flux controller manifests required by the selected release in [`base/flux`](../../base/flux). Install those pinned manifests before applying the Big Bang `GitRepository` and `HelmRelease` resources.

Optionally, checkout our documentation on [`Fluxing the Flux`](../concepts/git-ops-engine.md), using the Flux controllers to reconcile the Flux controller configuration

The repository script creates the registry pull secret when credentials are supplied, applies the local Flux manifests, and waits for the controllers:

```shell
./scripts/install_flux.sh --help
./scripts/install_flux.sh \
  --registry-username "$REGISTRY1_USERNAME" \
  --registry-password "$REGISTRY1_TOKEN"
```

Run the script from a checkout of the exact Big Bang release being installed. Do not install production Flux controllers from a moving `main` or `master` reference. If Flux is managed separately, confirm that its CustomResourceDefinitions and controllers are compatible with the API versions in [`base/`](../../base) and the rendered chart.

After installation, verify the controllers before reconciling Big Bang:

```shell
flux check
kubectl get pods -n flux-system
```

## Credentials and Licensing

Prepare least-privilege credentials for every private Git, Helm, OCI, and image registry used by the deployment. Store secrets using the environment repository's approved SOPS workflow rather than plaintext.

Review Big Bang's [licensing model](../concepts/licensing.md) and the license requirements of every enabled package.
