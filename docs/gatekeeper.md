# Kyverno Policies vs. Gatekeeper Policies in Big Bang

The following table shows the policies implemented in Big Bang under Gatekeeper and the corresponding policy in Kyverno.

> GK = Gatekeeper
> KY = Kyverno

|Name|Category|Description|Gatekeeper|Kyverno|Notes|
|--|--|--|--|--|--|
|AppArmor|Pod Security Standards (Baseline)|Restrict AppArmor profiles to allowed list|`allowedAppArmorProfiles`|`restrict-apparmor`|Disabled in GK|
|Default Service Account|Unknown|Disallow use of default service account|`noDefaultServiceAccount`|Will not implement|Kubernetes assigns the default service account to all pods that do not specify a service account.  Policy value is below threshold for implementation.  KY policy `update-token-automount` likely covers what this policy was intended to do.|
|Docker Registries|Best Practices (Security)|Restrict image registries to allowed list|`allowedDockerRegistries`|`restrict-image-registries`||
|External IPs|Vulnerability Mitigation|Restrict service's external IPs to allowed list|`allowedIPs`|`restrict-external-ips`|GK uses CIDR range.  KY uses regex.|
|Group IDs - Non-root|Pod Security Standards (Restricted)|Require groups to be non-root|`allowedUsers`|`require-non-root-group`||
|Group IDs - Range|Best Practices (Security)|Restrict group IDs to a specified range|`allowedUsers`|`restrict-group-id`||
|Host Namespace|Pod Security Standards (Baseline)|Disallow access to the host PID and IPC|`noHostNamespace`|`disallow-host-namespaces`||
|Host Networking|Pod Security Standards (Baseline)|Disallow sharing the host network|`hostNetworking`|`disallow-host-namespaces`||
|Host Path|Best Practices (Security)|Restrict volumes that map host paths to allowed list and require the volume mount to be read-only|`allowedHostFilesystem`|`restrict-host-path-mount`; `restrict-host-path-write`||
|Host Ports|Pod Security Standards (Baseline)|Restrict host ports to a specified range|`hostNetworking`|`restrict-host-ports`||
|Image Digest|Best Practices (Security)|Require images to use image digests instead of tags|`imageDigest`|Will not implement|Iron Bank images require tags for nightly image builds.  Policy value is below threshold for implementation.|
|Image Tags|Best Practices|Allow image tags not on banned list|`bannedImageTags`|`disallow-image-tags`||
|Ingress - HTTPS Only|Best Practices (Security)|Require ingresses to be HTTPS only|`httpsOnly`|Will not implement|Big Bang uses Istio instead of Ingresses.  Policy value is below threshold for implementation.|
|Ingress - Unique|Best Practice|Disallows multiple Ingresses with the same host|`uniqueIngressHost`|Will not implement|Big Bang uses Istio instead of Ingresses.  Policy value is below threshold for implementation.|
|Istio Sidecar Injection - Namespace|Best Practices|Require namespaces to be annotated for automatic Istio sidecar injection|`namespacesHaveIstio`|`require-istio-on-namespaces`||
|Istio Sidecar Injection - Pod|Best Practices|Require pods don't disable automatic Istio sidecar injection|`podsHaveIstio`|`disallow-istio-injection-bypass`||
|Labels|Best Practices|Require specified labels to be on resources|`requiredLabels`|`require-labels`|KY removed `component`, `part-of`, and `managed-by` from default required list.|
|Linux Capabilities|Pod Security Standards (Restricted)|Require all capabilities to be dropped and restrict added capabilities to allowed list|`allowedCapabilities`|`require-drop-all-capabilities`; `restrict-capabilities`| KY adds `NET_BIND_SERVICE` to the default allowed list|
|Node Ports|Best Practices (Security)|Disallow NodePort services|`blockNodePort`|`disallow-nodeport-services`||
|Privileged Containers|Pod Security Standards (Baseline)|Disallow containers that run as privileged|`noPrivilegedContainers`|`disallow-privileged-containers`||
|Privileged Escalation|Pod Security Standards (Restricted)|Disallow privilege escalation permissions|`noPrivilegedEscalation`|`disallow-privileged-containers`||
|Probes|Best Practices|Require probes on pods|`requiredProbes`|`require-probes`|KY removes validation of probe types (e.g. `tcpSocket`, `httpGet`, `exec`)|
|Proc Mount|Pod Security Standards (Baseline)|Restrict proc mount to allowed list|`allowedProcMount`|`restrict-proc-mount`||
|Read-only Root Filesystem|Best Practices (Security)|Require root file systems to be read only|`readOnlyRoot`|`require-ro-rootfs`||
|Resources - Large|Best Practices|Require CPU and memory limits and disallow extremely large values|`noBigContainers`|`require-cpu-limit; require-memory-limit`||
|Resources - Ratio|Best Practices|Ensure CPU and memory limits are not disproportionate to requests|`containerRatio`|Will not implement|No use case.  Policy value is below threshold for implementation.|
|SecComp|Pod Security Standards (Baseline)|Restrict SecComp profiles to allowed list|`allowedSecCompProfiles`|`restrict-seccomp`|KY adds `Localhost` to the default allowed list|
|SELinux|Pod Security Standards (Baseline)|Restrict SELinux options to allowed list|`seLinuxPolicy`|`disallow-selinux-options`; `restrict-selinux-type`|KY adds additional allowed values to the default allowed list|
|SysCtl|Pod Security Standards (Baseline)|Restrict SysCtls to allowed list|`noSysctls`|`restrict-sysctl`|KY adds additional sysctl values to the default allowed list|
|Tolerations|Best Practices (Security)|Tolerations must not match specified list of taints|`restrictedTaint`|`disallow-tolerations`|KY also prevents tolerations on `RuntimeClasses`|
|User IDs - Non-root|Pod Security Standards (Restricted)|Require user to run as non-root|`allowedUsers`|`require-non-root-user`||
|User IDs - Range|Best Practices (Security)|Restrict user IDs to a specified range|`allowedUsers`|`restrict-user-id`||
|Volumes - Flex|Historical|Restrict flex volume drivers to allowed list|`allowedFlexVolumes`|`restrict-volume-types`|Flex Volume drivers are deprecated.  In KY, Flex Volumes are not allowed.|
|Volumes - Types|Pod Security Standards (Restricted)|Restrict volume types to allowed list|`volumeTypes`|`restrict-volume-types`|KY adds `csi`and `ephemeral` to the default allowed list.|
