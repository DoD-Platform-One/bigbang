# OS Configuration Pre-Requisites:


## Disable swap (Kubernetes Best Practice)
1. Identify configured swap devices and files with cat /proc/swaps.
2. Turn off all swap devices and files with swapoff -a.
3. Remove any matching reference found in /etc/fstab.
(Credit: Above copy pasted from Aaron Copley of [Serverfault.com](https://serverfault.com/questions/684771/best-way-to-disable-swap-in-linux))


## ECK specific configuration (ECK is a Core BB App):
Elastic Cloud on Kubernetes (Elasticsearch Operator) deployed by BigBang uses memory mapping by default. In most cases, the default address space is too low and must be configured.
To ensure unnecessary privileged escalation containers are not used, these kernel settings should be applied before BigBang is deployed:

```bash
sudo sysctl -w vm.max_map_count=262144      #(ECK crash loops without this)
```

More information can be found from elasticsearch's documentation [here](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-virtual-memory.html#k8s-virtual-memory)


## SELinux specific configuration:
* If SELinux is enabled and the OS hasn't received additional pre-configuration, then users will see istio init-container crash loop.
* Depending on security requirements it may be possible to set selinux in permissive mode: `sudo setenforce 0`.
* Additional OS and Kubernetes specific configuration are required for istio to work on systems with selinux set to `Enforcing`.

By default, BigBang will deploy istio configured to use `istio-init` (read more [here](https://istio.io/latest/docs/setup/additional-setup/cni/)).  To ensure istio can properly initialize enovy sidecars without container privileged escalation permissions, several system kernel modules must be pre-loaded before installing BigBang:

```bash
modprobe xt_REDIRECT
modprobe xt_owner
modprobe xt_statistic
```


## Sonarqube specific configuration (Sonarqube is a BB Addon App):
Sonarqube requires the following kernel configurations set at the node level: 

```bash
sysctl -w vm.max_map_count=524288
sysctl -w fs.file-max=131072
ulimit -n 131072
ulimit -u 8192
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

