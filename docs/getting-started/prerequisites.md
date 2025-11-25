# Prerequisites

[[_TOC_]]

## Minimum Hardware Requirements

Each package will include its own recommended minimum hardware requirements, typically specified as resource requests and limits in the `values.yaml` file. Deploying additional packages will increase the overall requirements. However, the following hardware specifications are recommended for a default Big Bang installation:

<!-- TODO: Review and update these values based on the latest testing and requirements. -->
- **CPU:** 4 cores
- **Memory:** 16 GB
- **Disk:** 100 GB

It is also recommended to have a minimum of 3 nodes in the cluster to ensure high availability and fault tolerance. This allows for redundancy in case one or more nodes fail or require maintenance. If possible, those nodes should be distributed across multiple availability zones to further enhance resilience. Given that some of the nodes may fail, it is important to have enough resources available to handle the workload even when one or more nodes are down.

## OS Configuration

### Disable Swap (Kubernetes Best Practice)

1. Identify configured swap devices and files with cat /proc/swaps.
2. Turn off all swap devices and files with swapoff -a.
3. Remove any matching reference found in /etc/fstab.
(Credit: Above copy pasted from Aaron Copley of [Serverfault.com](https://serverfault.com/questions/684771/best-way-to-disable-swap-in-linux))

### ECK Specific Configuration (ECK Is a Core BB App)

<!-- TODO: move this section to the package. -->

Elastic Cloud on Kubernetes (i.e., Elasticsearch Operator) deployed by Big Bang uses memory mapping by default. In most cases, the default address space is too low and must be configured.
To ensure unnecessary privileged escalation containers are not used, these kernel settings should be applied before BigB ang is deployed:

```shell
sudo sysctl -w vm.max_map_count=262144      #(ECK crash loops without this)
```
To verify that this setting is in place and check the current value, after Big Bang deployment run the following command:
```shell
kubectl exec $(kubectl get pod -n eck-operator -l app.kubernetes.io/name=elastic-operator -o name) --namespace eck-operator -it -- cat /proc/sys/vm/max_map_count
```
This should return 262144 (or higher)


More information can be found from elasticsearch's documentation [here](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-virtual-memory.html#k8s-virtual-memory)

#### AKS Configuration

Ensure this block is present in the terraform configuration for the `azurerm_kubernetes_cluster_node_pool` resource section for your AKS cluster:

```yaml
linux_os_config {
  sysctl_config {
    vm_max_map_count = 262144
  }
}
```

### SELinux Specific Configuration

* If SELinux is enabled and the OS hasn't received additional pre-configuration, then users will see istio init-container crash loop.
* Depending on security requirements it may be possible to set selinux in permissive mode: `sudo setenforce 0`.
* Additional OS and Kubernetes specific configuration are required for istio to work on systems with selinux set to `Enforcing`.

By default, Big Bang will deploy istio configured to use `istio-init` (read more [here](https://istio.io/latest/docs/setup/additional-setup/cni/)).  To ensure istio can properly initialize envoy sidecars without container privileged escalation permissions, several system kernel modules must be pre-loaded before installing BigBang:

```shell
modprobe xt_REDIRECT
modprobe xt_owner
modprobe xt_statistic
```

### Sonarqube Specific Configuration (Sonarqube Is a BB Addon App)

<!-- TODO: move this section to the package. -->

Sonarqube requires the following kernel configurations set at the node level:

```shell
sysctl -w vm.max_map_count=524288
sysctl -w fs.file-max=131072
ulimit -n 131072
ulimit -u 8192
```
To verify these settings are in place (or check current values) run the following command:

```shell
kubectl exec $(kubectl get pod -n sonarqube -l app=sonarqube -o name) --namespace sonarqube -it -- cat /proc/sys/vm/max_map_count

This should return 524288 (or higher)

kubectl exec $(kubectl get pod -n sonarqube -l app=sonarqube -o name) --namespace sonarqube -it -- cat /proc/sys/fs/file-max

This should return 131072 (or higher)

kubectl exec $(kubectl get pod -n sonarqube -l app=sonarqube -o name) --namespace sonarqube -it -- ulimit -n

This should return 131072 (or higher)

kubectl exec $(kubectl get pod -n sonarqube -l app=sonarqube -o name) --namespace sonarqube -it -- ulimit -u

This should return 8192 (or higher)
```

Another option includes running the init container to modify the kernel values on the host (this requires a busybox container run as root):

```yaml
addons:
  sonarqube:
    values:
      initSysctl:
        enabled: true
```

**This is not the recommended solution as it requires running an init container as privileged.**

### Packages That Require Additional OS Configuration

Big Bang packages may require additional OS configuration to function properly. The following packages have specific requirements, you can find more information in their respective documentation at `docs/prerequisites.md`:
<!-- TODO: Link to package specific prerequisites. -->
- [ECK (Elasticsearch Operator)](https://repo1.dso.mil/big-bang/product/packages/eck-operator)
- [Sonarqube](https://repo1.dso.mil/big-bang/product/packages/sonarqube)

## Kubernetes Cluster

### Best Practices

* A Container Network Interface (CNI) that supports Network Policies, which are basically firewalls for the Inner Cluster Network. 
**NOTE:** k3d, which is recommended for the quickstart demo, defaults to flannel, which does not support network policies.
* All Kubernetes Nodes and the LB associated with the kube-apiserver should all use private IPs.
* In most case User Application Facing LBs should have Private IP Addresses and be paired with a defense in depth Ingress Protection mechanism like [P1's CNAP](https://p1.dso.mil/#/products/cnap/), a CNAP equivalent (e.g., Advanced Edge Firewall), VPN, VDI, port forwarding through a bastion, or air gap deployment.
* CoreDNS in the kube-system namespace should be HA with pod anti-affinity rules
* Master Nodes should be HA and tainted.
* Consider using a licensed Kubernetes Distribution with a support contract.
* [A default storage class should exist](#default-storage-class) to support dynamic provisioning of persistent volumes.

### Service of Type Load Balancer

Big Bang's default configuration assumes the cluster you're deploying to supports dynamic load balancer provisioning. Specifically, Istio defaults to creating a Kubernetes Service of type Load Balancer, which usually creates an endpoint exposed outside of the cluster that can direct traffic inside the cluster to the istio ingress gateway.

How Kubernetes service of type LB works depends on implementation details, there are many ways of getting it to work, common methods are listed in the following:

* CSP API Method (Recommended option for Cloud Deployments):
The Kubernetes Control Plane has a --cloud-provider flag that can be set to aws and/or azure. If the Kubernetes Master Nodes have that flag set and CSP IAM rights. The control plane will auto provision and configure CSP LBs. 
**NOTE:** A Vendors Kubernetes Distribution automation, may have IaC/CaC defaults that allow this to work turn key, but if you have issues when provisioning LBs, consult with the Vendor's support for the recommended way of configuring automatic LB provisioning.
* External LB Method (Good for bare metal and 0 IAM rights scenarios):
You can override bigbang's helm values so istio will provision a service of type NodePort instead of type LoadBalancer. Instead of randomly generating from the port range of 30000 - 32768, the NodePorts can be pinned to convention based port numbers like 30080 & 30443. If you're in a restricted cloud env or bare metal, you can ask someone to provision a CSP LB where LB:443 would map to Nodeport:30443 (of every worker node).
* No LB, Network Routing Methods (Good options for bare metal):
  * [MetalLB](https://metallb.universe.tf/)
  * [kubevip](https://kube-vip.io/)
  * [kube-router](https://www.kube-router.io)

### Big Bang Doesn’t Support Pod Security Policies (PSPs)

<!-- TODO: update this section to reflect the latest status of PSPs in Big Bang. -->

* [PSPs are being removed from Kubernetes and will be gone by version 1.25.x](https://repo1.dso.mil/big-bang/bigbang/-/issues/10)
* [Open Policy Agent Gatekeeper can enforce the same security controls as PSPs](https://github.com/open-policy-agent/gatekeeper-library/tree/master/library/pod-security-policy#pod-security-policies), and is core component of BigBang, which operates as an elevated [validating admission controller](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/) to audit and enforce various [constraints](https://github.com/open-policy-agent/frameworks/tree/master/constraint) on all requests sent to the kubernetes api server.
* We recommend users disable PSPs completely given they're being removed, we have a replacement, and PSPs can prevent OPA from deploying. If OPA is not able to deploy, nothing else gets deployed.
* Different ways of Disabling PSPs:
  * Edit the kube-apiserver's flags; methods for doing this vary per distribution.

  * ```shell
    kubectl patch psp system-unrestricted-psp -p '{"metadata": {"annotations":{"seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*"}}}'
    kubectl patch psp global-unrestricted-psp -p '{"metadata": {"annotations":{"seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*"}}}'
    kubectl patch psp global-restricted-psp -p '{"metadata": {"annotations":{"seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*"}}}'
    ```
* [Kyverno can enforce similar security controls](https://kyverno.io/blog/2023/05/24/podsecuritypolicy-migration-with-kyverno/)

### Kubernetes Distribution Specific Notes

<!-- TODO: this should probably be removed, none of these are maintained. -->

* **NOTE:** P1 has forks of various [Kubernetes Distribution Vendor Repos](https://repo1.dso.mil/platform-one/distros), there's nothing special about the P1 forks.
* We recommend you leverage the Vendors upstream docs in addition to any docs found in P1 Repos; in fact, the Vendor's upstream docs are far more likely to be up to date.

#### Kubernetes Version

It is important to note that while Big Bang does not require/mandate usage of a specific Kubernetes Version, we also do not do extensive testing on every version. Our general stance on Kubernetes versions is provided in the following:
* Big Bang supports any non-EOL Kubernetes version listed under https://kubernetes.io/releases/. This will be represented by `kubeVersion` in the Chart.yaml of the Big Bang Helm Chart.
* Big Bang release and CI testing will primarily be done on the `n-1` minor Kubernetes version (i.e. if 1.27.x is latest, we will test on 1.26.x). We will generally keep our testing environments on the latest patch for that minor version.
* New features added by Kubernetes will be kept behind feature gates until all non-EOL versions support those features.

#### VMWare Tanzu Kubernetes Grid

[Prerequisites section of VMware Kubernetes Distribution Docs](https://repo1.dso.mil/platform-one/distros/vmware/tkg#prerequisites)

#### Cluster API

**NOTE:** There are some OS hardening and VM Image Build automation tools in here, in addition to Cluster API.
* <https://repo1.dso.mil/platform-one/distros/clusterapi>
* <https://repo1.dso.mil/platform-one/distros/cluster-api/gov-image-builder>

#### OpenShift

1. When deploying Big Bang, set the OpenShift flag to true.

    ```yaml
    # inside a values.yaml being passed to the command installing bigbang
    openshift: true
    ```

    ```shell
    # OR inline with helm command
    helm install bigbang chart --set openshift=true
    ```

1. Patch the istio-cni daemonset to allow containers to run privileged (AFTER istio-cni daemonset exists).

    Note: it was unsuccessfully attempted to apply this setting via modifications to the helm chart. Online patching succeeded.

    ```shell
    kubectl get daemonset istio-cni-node -n kube-system -o json | jq '.spec.template.spec.containers[] += {"securityContext":{"privileged":true}}' | kubectl replace -f -
    ```

1. Modify the OpenShift cluster(s) with the following scripts based on <https://istio.io/v1.7/docs/setup/platform-setup/openshift/>.

    ```shell
    # Istio Openshift configurations Post Install
    oc -n istio-system expose svc/public-ingressgateway --port=http2
    oc adm policy add-scc-to-user privileged -z istio-cni -n kube-system
    oc adm policy add-scc-to-group privileged system:serviceaccounts:logging
    oc adm policy add-scc-to-group anyuid system:serviceaccounts:logging
    oc adm policy add-scc-to-group privileged system:serviceaccounts:monitoring
    oc adm policy add-scc-to-group anyuid system:serviceaccounts:monitoring

    cat <<\EOF >> NetworkAttachmentDefinition.yaml
    apiVersion: "k8s.cni.cncf.io/v1"
    kind: NetworkAttachmentDefinition
    metadata:
      name: istio-cni
    EOF
    oc -n logging create -f NetworkAttachmentDefinition.yaml
    oc -n monitoring create -f NetworkAttachmentDefinition.yaml
    ```

#### Konvoy

* [Prerequisites can be found here](https://repo1.dso.mil/platform-one/distros/d2iq/konvoy/konvoy/-/tree/master/docs/1.5.0#prerequisites)
* Konvoy clusters need a [Metrics API Endpoint](https://github.com/kubernetes/metrics#resource-metrics-api) available within the cluster to allow Horizontal Pod Autoscalers to correctly fetch pod/deployment metrics.
* [Different Deployment Scenarios have been documented here](https://repo1.dso.mil/platform-one/distros/d2iq/konvoy/konvoy/-/tree/master/docs/1.4.4/install)

#### RKE2

* RKE2 turns PSPs on by default (see above for tips on disabling).
* RKE2 sets selinux to enforcing by default ([see os configuration section](#os-configuration) for selinux config).

Since BigBang makes several assumptions about volume and load balancing provisioning by default, it's vital that the rke2 cluster must be properly configured. The easiest way to do this is through the in tree cloud providers, which can be configured through the `rke2` configuration file such as:

```yaml
# aws, azure, gcp, etc...
cloud-provider-name: aws

# additionally, set below configuration for private AWS endpoints, or custom regions such as (T)C2S (us-iso-east-1, us-iso-b-east-1)
cloud-provider-config: ...
```

For example, if using the aws terraform modules provided [on repo1](https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-aws-terraform), setting the variable: `enable_ccm = true` will ensure all the necessary resources tags.

In the absence of an in-tree cloud provider (e.g., on-prem), the requirements can be met by ensuring a default storage class and automatic load balancer provisioning exist.

## Default Storage Class

* Big Bang assumes the cluster you're deploying to supports [dynamic volume provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/).
* A Big Bang cluster should have 1 Storage Class (SC) annotated as the default SC.
* For production deployments, it is recommended to leverage a SC that supports the creation of volumes that support ReadWriteMany [Access Mode](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes), as there are a few Big Bang add-ons, where an HA application configuration requires a storage class that supports ReadWriteMany.

### How Dynamic Volume Provisioning Works in a Nut Shell

* StorageClass + PersistentVolumeClaim = Dynamically Created Persistent Volume
* A PersistentVolumeClaim that does not reference a specific SC will leverage the default SC, of which there should only be one, identified using Kubernetes annotations. Some helm charts allow a SC to be explicitly specified so that multiple SCs can be used simultaneously.

### How To Check What Storage Classes Are Installed on Your Cluster

* `kubectl get storageclass` can be used to see what storage classes are available on a cluster; the default will be marked accordingly.
**NOTE:** You can have multiple storage classes, but you should only have one default storage class.

```shell
kubectl get storageclass
# NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
# local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  47h
```

------------------------------------------------------

### AWS Specific Notes

<!-- TODO: make sure this section is up to date with the latest AWS Storage Class and EBS/EFSS requirements. -->

#### Example AWS Storage Class Configuration

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: gp2
  annotations:
    storageclass.kubernetes.io/is-default-class: 'true'
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2 #gp3 isn't supported by the in-tree plugin
  fsType: ext4
#  encrypted: 'true' #requires kubernetes nodes have IAM rights to a KMS key
#  kmsKeyId: 'arn:aws-us-gov:kms:us-gov-west-1:110518024095:key/b6bf63f0-dc65-49b4-acb9-528308195fd6'
reclaimPolicy: Retain
allowVolumeExpansion: true
```

#### AWS EBS Volumes

* AWS EBS Volumes have the following limitations:
  * An EBS volume can only be attached to a single Kubernetes Node at a time, thus ReadWriteMany Access Mode isn't supported.
  * An EBS PersistentVolume in Availability Zone (AZ) 1, cannot be mounted by a worker node in AZ2.

#### AWS EFS Volumes

* An AWS EFS Storage Class can be installed according to the [vendors docs](https://github.com/kubernetes-sigs/aws-efs-csi-driver#installation).
* AWS EFS Storage Class supports ReadWriteMany Access Mode.
* AWS EFS Persistent Volumes can be mounted by worker nodes in multiple AZs.
* AWS EFS is basically NetworkFileSystem (NFS) as a Service. NFS cons like latency apply equally to EFS, and therefore it's not a good fit for for databases.  

------------------------------------------------------

### Azure Specific Notes

#### Azure Disk Storage Class Notes

<!-- TODO: make sure this section is up to date with the latest Azure Storage Class and Disk requirements. -->

* The Kubernetes Docs offer an example [Azure Disk Storage Class](https://kubernetes.io/docs/concepts/storage/storage-classes/#azure-disk)
* An Azure disk can only be mounted with Access mode type ReadWriteOnce, which makes it available to one node in AKS.
* An Azure Disk PersistentVolume in AZ1 can be mounted by a worker node in AZ2, although some additional lag is involved in such transitions.

------------------------------------------------------

### Bare Metal/Cloud Agnostic Store Class Notes

* The Big Bang Product team put together a [Comparison Matrix of a few Cloud Agnostic Storage Class offerings](../community/development/k8s-storage.md#kubernetes-storage-options)

  **NOTE:** No storage class specific container images exist in IronBank at this time.
  * Approved IronBank Images will show up in <https://registry1.dso.mil>.
  * <https://repo1.dso.mil/dsop> can be used to check status of IronBank images.

## Flux

### Install the Flux CLI Tool

```shell
sudo curl -s https://fluxcd.io/install.sh | sudo bash
```

> Fedora Note: kubectl is a prereq for flux, and flux expects it in `/usr/local/bin/kubectl` symlink it or copy the binary to fix errors.

### Install flux.yaml to the Cluster

```shell
export REGISTRY1_USER='REPLACE_ME'
export REGISTRY1_TOKEN='REPLACE_ME'
```

> In production use robot credentials, single quotes are important due to the '$'  
`export REGISTRY1_USER='robot$bigbang-onboarding-imagepull'`

```shell
kubectl create ns flux-system
kubectl create secret docker-registry private-registry \
    --docker-server=registry1.dso.mil \
    --docker-username=$REGISTRY1_USER \
    --docker-password=$REGISTRY1_TOKEN \
    --namespace flux-system
kubectl apply -k https://repo1.dso.mil/big-bang/bigbang.git//base/flux?ref=master
```
**NOTE:** You can replace ```master``` in the ```kubectl apply -k``` command above with tag of the Big Bang release you need. For example:
```
kubectl apply -k https://repo1.dso.mil/big-bang/bigbang/bigbang.git//base/flux?ref=2.14.0
```

#### Now You Can See New CRD Objects Types Inside the Cluster

```shell
kubectl get crds | grep flux
```

### Advanced Installation

Clone the Big Bang repo and use the awesome installation [scripts](https://repo1.dso.mil/big-bang/bigbang/-/tree/master/scripts) directory.

```shell
git clone https://repo1.dso.mil/big-bang/bigbang.git
./bigbang/scripts/install_flux.sh
```

> **NOTE:** install_flux.sh requires arguments to run properly, calling it will print out a friendly USAGE message with required arguments needed to complete installation.

## Licensing

Review Big Bangs's [Licensing Model](../concepts/licensing.md).
