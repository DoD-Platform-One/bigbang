# Appendix D - Big Bang Prerequisites

BigBang is built to work on all the major kubernetes distributions.  However, since distributions differ and may come
configured out the box with settings incompatible with BigBang, this document serves as a checklist of pre-requisites
for any distribution that may need it.

> Clusters are sorted _alphabetically_

## All Clusters

The following apply as prerequisites for all clusters

### Storage

BigBang assumes the cluster you're deploying to supports [dynamic volume provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/).  Which ultimatley puts the burden on the cluster distro provider to ensure appropriate setup.  In many cases, this is as simple as using the in-tree CSI drivers.  Please refer to each supported distro's documentation for further details.

In the future, BigBang plans to support the provisioning and management of a cloud agnostic container attached storage solution, but until then, on-prem deployments require more involved setup, typically supported through the vendor.

#### Default `StorageClass`

A default `StorageClass` capable of resolving `ReadWriteOnce` `PersistentVolumeClaims` must exist.  An example suitable for basic production workloads on aws that supports a highly available cluster on multiple availability zones is provided below:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
reclaimPolicy: Delete
allowVolumeExpansion: true
mountOptions:
  - debug
volumeBindingMode: WaitForFirstConsumer
```

It is up to the user to ensure the default storage class' performance is suitable for their workloads, or to specify different `StorageClasses` when necessary.

### `selinux`

Additional pre-requisites are needed for istio on systems with selinux set to `Enforcing`.

By default, BigBang will deploy istio configured to use `istio-init` (read more [here](https://istio.io/latest/docs/setup/additional-setup/cni/)).  To ensure istio can properly initialize enovy sidecars without container privileged escalation permissions, several system kernel modules must be pre-loaded before installing BigBang:

```bash
modprobe xt_REDIRECT
modprobe xt_owner
modprobe xt_statistic
```

### Load Balancing

BigBang by default assumes the cluster you're deploying to supports dynamic load balancing provisioning.  Specifically during the creation of istio and it's ingress gateways, which map to a "physical" load balancer usually provisioned by the cloud provider.

In almost all cases, the distro provides this capability through in-tree cloud providers appropriately configured through the IAC on repo1.  For on-prem environments, please consult with the vendors support for the recommended way of handling automatic load balancing configuration.

If automatic load balancing provisioning is not support or not desired, the default BigBang configuration can be modified to expose istio's ingressgateway through `NodePorts` that can manually (or separate IAC) be mapped to a pre-existing loadbalancer.

### Elasticsearch

Elasticsearch deployed by BigBang uses memory mapping by default.  In most cases, the default address space is too low and must be configured.

To ensure unnecessary privileged escalation containers are not used, these kernel settings should be done before BigBang is deployed:

```bash
sysctl -w vm.max_map_count=262144
```

More information can be found from elasticsearch's documentation [here](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-virtual-memory.html#k8s-virtual-memory)

## OpenShift

1) When deploying BigBang, set the OpenShift flag to true.

```
# inside a values.yaml being passed to the command installing bigbang
openshift: true

# OR inline with helm command
helm install bigbang chart --set openshift=true
```

2) Patch the istio-cni daemonset to allow containers to run privileged (AFTER istio-cni daemonset exists).  
Note: it was unsuccessfully attempted to apply this setting via modifications to the helm chart. Online patching succeeded. 
   
```
kubectl get daemonset istio-cni-node -n kube-system -o json | jq '.spec.template.spec.containers[] += {"securityContext":{"privileged":true}}' | kubectl replace -f -
```

3) Modify the OpenShift cluster(s) with the following scripts based on https://istio.io/v1.7/docs/setup/platform-setup/openshift/

```
# Istio Openshift configurations Post Install 
oc -n istio-system expose svc/istio-ingressgateway --port=http2
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

## RKE2

Since BigBang makes several assumptions about volume and load balancing provisioning by default, it's vital that the rke2 cluster must be properly configured.  The easiest way to do this is through the in tree cloud providers, which can be configured through the `rke2` configuration file such as:

```yaml
# aws, azure, gcp, etc...
cloud-provider-name: aws

# additionally, set below configuration for private AWS endpoints, or custom regions such as (T)C2S (us-iso-east-1, us-iso-b-east-1)
cloud-provider-config: ...
```

For example, if using the aws terraform modules provided [on repo1](https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-aws-terraform), setting the variable: `enable_ccm = true` will ensure all the necessary resources tags.

In the absence of an in-tree cloud provider (such as on-prem), the requirements can be met through the instructions outlined in the [storage](#storage) and [load balancing](#load-balancing) prerequisites section above.

### OPA Gatekeeper

A core component to Bigbang is OPA Gatekeeper, which operates as an elevated  [validating admission controller](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/) to audit and enforce various [constraints](https://github.com/open-policy-agent/frameworks/tree/master/constraint) on all requests sent to the kubernetes api server.

By default, `rke2` will deploy with [Pod Security Policies](https://kubernetes.io/docs/concepts/policy/pod-security-policy/) that disable these type of deployments.  However, since we trust Bigbang (and OPA gatekeeper), we can patch the default `rke2` psp's to allow OPA.

Given a freshly installed `rke2` cluster, run the following commands _once_ before attempting to install BigBang.

```bash
kubectl patch psp system-unrestricted-psp  -p '{"metadata": {"annotations":{"seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*"}}}'
kubectl patch psp global-unrestricted-psp  -p '{"metadata": {"annotations":{"seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*"}}}'
kubectl patch psp global-restricted-psp  -p '{"metadata": {"annotations":{"seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*"}}}'
```

### Istio

By default, BigBang will use `istio-init`, and `rke2` clusters will come with `selinux` in `Enforcing` mode, please see the [`istio-init`](#istio-pre-requisites-on-selinux-enforcing-systems) above for pre-requisites and warnings.
