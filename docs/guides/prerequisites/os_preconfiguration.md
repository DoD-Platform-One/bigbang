# OS Configuration Pre-Requisites

## Disable Swap (Kubernetes Best Practice)

1. Identify configured swap devices and files with cat /proc/swaps.
2. Turn off all swap devices and files with swapoff -a.
3. Remove any matching reference found in /etc/fstab.
(Credit: Above copy pasted from Aaron Copley of [Serverfault.com](https://serverfault.com/questions/684771/best-way-to-disable-swap-in-linux))

## ECK Specific Configuration (ECK Is a Core BB App)

Elastic Cloud on Kubernetes (Elasticsearch Operator) deployed by BigBang uses memory mapping by default. In most cases, the default address space is too low and must be configured.
To ensure unnecessary privileged escalation containers are not used, these kernel settings should be applied before BigBang is deployed:

```shell
sudo sysctl -w vm.max_map_count=262144      #(ECK crash loops without this)
```
To verify that this setting is in place and check the current value, after Big Bang deployment run the following command:
```shell
kubectl exec $(kubectl get pod -n eck-operator -l app.kubernetes.io/name=elastic-operator -o name) --namespace eck-operator -it -- cat /proc/sys/vm/max_map_count
```
This should return 262144 (or higher)


More information can be found from elasticsearch's documentation [here](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-virtual-memory.html#k8s-virtual-memory)

### AKS Configuration

Ensure this block is present in the terraform configuration for the `azurerm_kubernetes_cluster_node_pool` resource section for your AKS cluster:

```yaml
linux_os_config {
  sysctl_config {
    vm_max_map_count = 262144
  }
}
```

## SELinux Specific Configuration

* If SELinux is enabled and the OS hasn't received additional pre-configuration, then users will see istio init-container crash loop.
* Depending on security requirements it may be possible to set selinux in permissive mode: `sudo setenforce 0`.
* Additional OS and Kubernetes specific configuration are required for istio to work on systems with selinux set to `Enforcing`.

By default, BigBang will deploy istio configured to use `istio-init` (read more [here](https://istio.io/latest/docs/setup/additional-setup/cni/)).  To ensure istio can properly initialize envoy sidecars without container privileged escalation permissions, several system kernel modules must be pre-loaded before installing BigBang:

```shell
modprobe xt_REDIRECT
modprobe xt_owner
modprobe xt_statistic
```

## Sonarqube Specific Configuration (Sonarqube Is a BB Addon App)

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
