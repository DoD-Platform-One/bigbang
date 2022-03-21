# Kubernetes Cluster Preconfiguration

## Best Practices

* A CNI (Container Network Interface) that supports Network Policies (which are basically firewalls for the Inner Cluster Network.) (Note: k3d, which is recommended for the quickstart demo, defaults to flannel, which does not support network policies.)
* All Kubernetes Nodes and the LB associated with the kube-apiserver should all use private IPs.
* In most case User Application Facing LBs should have Private IP Addresses and be paired with a defense in depth Ingress Protection mechanism like [P1's CNAP](https://p1.dso.mil/#/products/cnap/), a CNAP equivalent (Advanced Edge Firewall), VPN, VDI, port forwarding through a bastion, or air gap deployment.
* CoreDNS in the kube-system namespace should be HA with pod anti-affinity rules
* Master Nodes should be HA and tainted.
* Consider using a licensed Kubernetes Distribution with a support contract.
* [A default storage class should exist](default_storageclass.md) to support dynamic provisioning of persistent volumes.

## Service of Type Load Balancer

BigBang's default configuration assumes the cluster you're deploying to supports dynamic load balancer provisioning. Specifically Istio defaults to creating a Kubernetes Service of type Load Balancer, which usually creates an endpoint exposed outside of the cluster that can direct traffic inside the cluster to the istio ingress gateway.

How Kubernetes service of type LB works depends on implementation details, there are many ways of getting it to work, common methods are listed below:

* CSP API Method: (Recommended option for Cloud Deployments)
The Kubernetes Control Plane has a --cloud-provider flag that can be set to aws, azure, etc. If the Kubernetes Master Nodes have that flag set and CSP IAM rights. The control plane will auto provision and configure CSP LBs. (Note: a Vendors Kubernetes Distribution automation, may have IaC/CaC defaults that allow this to work turn key, but if you have issues when provisioning LBs, consult with the Vendor's support for the recommended way of configuring automatic LB provisioning.)
* External LB Method: (Good for bare metal and 0 IAM rights scenarios)
You can override bigbang's helm values so istio will provision a service of type NodePort instead of type LoadBalancer. Instead of randomly generating from the port range of 30000 - 32768, the NodePorts can be pinned to convention based port numbers like 30080 & 30443. If you're in a restricted cloud env or bare metal you can ask someone to provision a CSP LB where LB:443 would map to Nodeport:30443 (of every worker node), etc.
* No LB, Network Routing Methods: (Good options for bare metal)
  * [MetalLB](https://metallb.universe.tf/)
  * [kubevip](https://kube-vip.io/)
  * [kube-router](https://www.kube-router.io)

## BigBang Doesn’t Support PSPs (Pod Security Policies)

* [PSP's are being removed from Kubernetes and will be gone by version 1.25.x](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues/10)
* [Open Policy Agent Gatekeeper can enforce the same security controls as PSPs](https://github.com/open-policy-agent/gatekeeper-library/tree/master/library/pod-security-policy#pod-security-policies), and is core component of BigBang, which operates as an elevated [validating admission controller](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/) to audit and enforce various [constraints](https://github.com/open-policy-agent/frameworks/tree/master/constraint) on all requests sent to the kubernetes api server.
* We recommend users disable PSPs completely given they're being removed, we have a replacement, and PSPs can prevent OPA from deploying (and if OPA is not able to deploy, nothing else gets deployed).
* Different ways of Disabling PSPs:
  * Edit the kube-apiserver's flags (methods for doing this vary per distribution.)

  * ```shell
    kubectl patch psp system-unrestricted-psp -p '{"metadata": {"annotations":{"seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*"}}}'
    kubectl patch psp global-unrestricted-psp -p '{"metadata": {"annotations":{"seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*"}}}'
    kubectl patch psp global-restricted-psp -p '{"metadata": {"annotations":{"seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*"}}}'
    ```

## Kubernetes Distribution Specific Notes

* Note: P1 has forks of various [Kubernetes Distribution Vendor Repos](https://repo1.dso.mil/platform-one/distros), there's nothing special about the P1 forks.
* We recommend you leverage the Vendors upstream docs in addition to any docs found in P1 Repos; infact, the Vendor's upstream docs are far more likely to be up to date.

### VMWare Tanzu Kubernetes Grid

[Prerequisites section of VMware Kubernetes Distribution Docs's](https://repo1.dso.mil/platform-one/distros/vmware/tkg#prerequisites)

### Cluster API

* Note that there are some OS hardening and VM Image Build automation tools in here, in addition to Cluster API.
* <https://repo1.dso.mil/platform-one/distros/clusterapi>
* <https://repo1.dso.mil/platform-one/distros/cluster-api/gov-image-builder>

### OpenShift

OpenShift

1) When deploying BigBang, set the OpenShift flag to true.

    ```yaml
    # inside a values.yaml being passed to the command installing bigbang
    openshift: true
    ```

    ```shell
    # OR inline with helm command
    helm install bigbang chart --set openshift=true
    ```

1) Patch the istio-cni daemonset to allow containers to run privileged (AFTER istio-cni daemonset exists).
Note: it was unsuccessfully attempted to apply this setting via modifications to the helm chart. Online patching succeeded.

    ```shell
    kubectl get daemonset istio-cni-node -n kube-system -o json | jq '.spec.template.spec.containers[] += {"securityContext":{"privileged":true}}' | kubectl replace -f -
    ```

1) Modify the OpenShift cluster(s) with the following scripts based on <https://istio.io/v1.7/docs/setup/platform-setup/openshift/>

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

### Konvoy

* [Prerequisites can be found here](https://repo1.dso.mil/platform-one/distros/d2iq/konvoy/konvoy/-/tree/master/docs/1.5.0#prerequisites)
* Konvoy clusters need a [Metrics API Endpoint](https://github.com/kubernetes/metrics#resource-metrics-api) available within the cluster to allow Horizontal Pod Autoscalers to correctly fetch pod/deployment metrics.
* [Different Deployment Scenarios have been documented here](https://repo1.dso.mil/platform-one/distros/d2iq/konvoy/konvoy/-/tree/master/docs/1.4.4/install)

### RKE2

* RKE2 turns PSPs on by default (see above for tips on disabling)
* RKE2 sets selinux to enforcing by default ([see os_preconfiguration.md for selinux config](os_preconfiguration.md))

Since BigBang makes several assumptions about volume and load balancing provisioning by default, it's vital that the rke2 cluster must be properly configured.  The easiest way to do this is through the in tree cloud providers, which can be configured through the `rke2` configuration file such as:

```yaml
# aws, azure, gcp, etc...
cloud-provider-name: aws

# additionally, set below configuration for private AWS endpoints, or custom regions such as (T)C2S (us-iso-east-1, us-iso-b-east-1)
cloud-provider-config: ...
```

For example, if using the aws terraform modules provided [on repo1](https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-aws-terraform), setting the variable: `enable_ccm = true` will ensure all the necessary resources tags.

In the absence of an in-tree cloud provider (such as on-prem), the requirements can be met by ensuring a default storage class and automatic load balancer provisioning exist.
