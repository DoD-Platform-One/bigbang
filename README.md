# kyverno-policies

![Version: 1.0.0-bb.2](https://img.shields.io/badge/Version-1.0.0--bb.2-informational?style=flat-square)

Collection of Kyverno security and best-practice policies for Kyverno

## Upstream References
* <https://kyverno.io/policies/>

* <https://github.com/kyverno/policies>

## Learn More
* [Application Overview](docs/overview.md)
* [Other Documentation](docs/)

## Pre-Requisites

* Kubernetes Cluster deployed
* Kubernetes config installed in `~/.kube/config`
* Helm installed

Kubernetes: `>=1.10.0-0`

Install Helm

https://helm.sh/docs/intro/install/

## Deployment

* Clone down the repository
* cd into directory
```bash
helm install kyverno-policies chart/
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| enabled | bool | `true` | Enable policy deployments |
| validationFailureAction | string | `""` | Override all policies' validation failure action with "audit" or "enforce".  If blank, uses policy setting. |
| webhookTimeoutSeconds | string | `""` | Override all policies' time to wait for admission webhook to respond.  If blank, uses policy setting or default (10). |
| exclude | object | `{}` | Adds an exclusion to all policies.  This is merged with any policy-specific excludes. |
| customLabels | object | `{}` | Additional labels to apply to all policies. |
| policies.sample | object | `{"enabled":false,"exclude":{},"match":{},"parameters":{},"validationFailureAction":"audit","webhookTimeoutSeconds":""}` | Sample policy showing values that can be added to any policy |
| policies.sample.enabled | bool | `false` | Controls policy deployment |
| policies.sample.validationFailureAction | string | `"audit"` | Controls if a validation policy rule failure should disallow (enforce) or allow (audit) the admission |
| policies.sample.webhookTimeoutSeconds | string | `""` | Specifies the maximum time in seconds allowed to apply this policy. Default is 10. Range is 1 to 30. |
| policies.sample.match | object | `{}` | Defines when this policy's rules should be applied.  This completely overrides any default matches. |
| policies.sample.exclude | object | `{}` | Defines when this policy's rules should not be applied.  This completely overrides any default excludes. |
| policies.sample.parameters | object | `{}` | Policy specific parameters that are added to the configMap for the policy rules |
| policies.clone-configs | object | `{"enabled":false,"parameters":{"sourceObjects":{}}}` | Clone existing configMap or secret in new Namespaces |
| policies.clone-configs.parameters.sourceObjects | object | `{}` | ConfigMap or Secrets that should be cloned |
| policies.cve-add-lo4j2-mitigation | object | `{"enabled":false}` | Mitigates log4j2 vulnerability (CVE-2021-44228) for library versions >= 2.10 |
| policies.cve-restrict-external-ips | object | `{"enabled":true,"parameters":{"allowedValues":[]},"validationFailureAction":"enforce"}` | Mitigates Services with External IPs vulnerability (CVE-2020-8554) |
| policies.cve-restrict-external-ips.parameters.allowedValues | list | `[]` | List of external IPs allowed in services |
| policies.cve-restrict-external-names | object | `{"enabled":true,"parameters":{"allowedValues":[]},"validationFailureAction":"enforce"}` | Mitigates Services with External Names vulnerability (CVE-2020-8554) |
| policies.cve-restrict-external-names.parameters.allowedValues | list | `[]` | List of external names allowed in services.  Must be a lowercase FRC-1123 hostname. |
| policies.disallow-default-namespace | object | `{"enabled":true,"validationFailureAction":"audit"}` | Prevents deployment of pods into the default namespace |
| policies.disallow-deprecated-apis | object | `{"enabled":true,"validationFailureAction":"audit"}` | Checks for resource APIs in use that will be removed in Kubernetes 1.22 or 1.25 |
| policies.disallow-host-namespaces | object | `{"enabled":true,"validationFailureAction":"enforce"}` | Disallow use of the host namespace (PID, IPC, Network) by pods |
| policies.disallow-host-path | object | `{"enabled":true,"validationFailureAction":"enforce"}` | Disallow hostpath volumes |
| policies.disallow-nodeport-services | object | `{"enabled":true,"validationFailureAction":"audit"}` | Disallow services of type NodePort |
| policies.disallow-privilege-escalation | object | `{"enabled":true,"validationFailureAction":"audit"}` | Disallows pods that allow privilege escalation |
| policies.disallow-privileged-containers | object | `{"enabled":true,"validationFailureAction":"enforce"}` | Disallow containers that run as privileged |
| policies.disallow-rbac-on-default-serviceaccounts | object | `{"enabled":true,"validationFailureAction":"enforce"}` | Disallow additional permissions on default service accounts |
| policies.replace-image-registry | object | `{"enabled":false,"parameters":{"replacements":[]}}` | Replaces an existing image registry with a new registry in containers (e.g. proxy) |
| policies.replace-image-registry.parameters.replacements | list | `[]` | List of registries to replace |
| policies.require-drop-all-capabilities | object | `{"enabled":true,"validationFailureAction":"audit"}` | Requires containers to drop all Linux capabilities |
| policies.require-labels | object | `{"enabled":false,"parameters":{"requiredValues":["app.kubernetes.io/name","app.kubernetes.io/instance","app.kubernetes.io/version"]},"validationFailureAction":"audit"}` | Require specified labels to be on all pods |
| policies.require-labels.parameters.requiredValues | list | `["app.kubernetes.io/name","app.kubernetes.io/instance","app.kubernetes.io/version"]` | List of labels required on all pods See https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/#labels See https://helm.sh/docs/chart_best_practices/labels/#standard-labels |
| policies.require-non-root-group | object | `{"enabled":true,"validationFailureAction":"audit"}` | Require containers to run with non root group |
| policies.require-non-root-user | object | `{"enabled":true,"validationFailureAction":"audit"}` | Require containers to run as non root user |
| policies.require-probes | object | `{"enabled":true,"parameters":{"requiredValues":["readinessProbe","livenessProbe"]},"validationFailureAction":"audit"}` | Require specified probes on pods |
| policies.require-probes.parameters.requiredValues | list | `["readinessProbe","livenessProbe"]` | List of probes that are required on pods |
| policies.require-requests-equal-limits | object | `{"enabled":false,"validationFailureAction":"audit"}` | Require CPU and memory requests to equal limits so guaranteed quality of service is applied |
| policies.require-resource-limits | object | `{"enabled":true,"validationFailureAction":"audit"}` | Require all containers have CPU and memory limits specified |
| policies.require-ro-host-path | object | `{"enabled":true,"validationFailureAction":"enforce"}` | Require containers mount hostPath volumes as read-only.  HostPath volumes are normally disallowed.  But, if exceptions are made, the volume should be mounted as read-only. |
| policies.require-ro-rootfs | object | `{"enabled":true,"validationFailureAction":"audit"}` | Require containers set root filesystem to read-only |
| policies.restrict-apparmor | object | `{"enabled":true,"parameters":{"allowedValues":["runtime/default"]},"validationFailureAction":"audit"}` | Restricts pods that use AppArmor to specified profiles Iron Bank containers are either distroless or RHEL UBI.  Neither of these uses AppArmor |
| policies.restrict-apparmor.parameters.allowedValues | list | `["runtime/default"]` | List of allowed AppArmor profiles |
| policies.restrict-automount-sa-token | object | `{"enabled":false,"validationFailureAction":"audit"}` | *Disallow pods from automatically mounting the default service account |
| policies.restrict-capabilities | object | `{"enabled":true,"parameters":{"allowedValues":["NET_BIND_SERVICE"]},"validationFailureAction":"audit"}` | Restrict Linux capabilities that are allowed to be added in containers |
| policies.restrict-capabilities.parameters.allowedValues | list | `["NET_BIND_SERVICE"]` | List of capabilities that are allowed to be added Defaults pulled from https://kubernetes.io/docs/concepts/security/pod-security-standards/#restricted |
| policies.restrict-controlplane-scheduling | object | `{"enabled":false,"validationFailureAction":"audit"}` | *NEW |
| policies.restrict-group-id | object | `{"enabled":true,"parameters":{"allowedValues":[">=1000"]},"validationFailureAction":"audit"}` | Restrict container group IDs to allowed ranges NOTE: Using require-non-root-group will force runAsGroup to be defined |
| policies.restrict-group-id.parameters.allowedValues | list | `[">=1000"]` | Allowed group IDs / ranges.  The following operators are valid: >, <, >=, <=, !, |, &. For a lower and upper limit, use ">=min & <=max" |
| policies.restrict-host-path | object | `{"enabled":true,"parameters":{"allowedValues":[]},"validationFailureAction":"enforce"}` | Restrict hostPath volume paths to the allowed list.  HostPath volumes are normally disallowed.  But, if exceptions are made, the path should be restricted. |
| policies.restrict-host-path.parameters.allowedValues | list | `[]` | List of allowed paths for hostPath volumes |
| policies.restrict-host-ports | object | `{"enabled":true,"parameters":{"allowedValues":[]},"validationFailureAction":"enforce"}` | Restrict containers using host ports to the allowed list |
| policies.restrict-host-ports.parameters.allowedValues | list | `[]` | List of allowed host ports |
| policies.restrict-image-registries | object | `{"enabled":true,"parameters":{"allowedValues":["registry1.dso.mil"]},"validationFailureAction":"enforce"}` | Restricts container images to registries in approved list |
| policies.restrict-image-registries.parameters.allowedValues | list | `["registry1.dso.mil"]` | List of allowed registries that images may use |
| policies.restrict-image-tags | object | `{"enabled":true,"parameters":{"disallowedValues":["latest"]},"validationFailureAction":"enforce"}` | Restricts container image tags based on blacklist |
| policies.restrict-proc-mount | object | `{"enabled":true,"parameters":{"allowedValues":["Default"]},"validationFailureAction":"enforce"}` | Restrict container's use of procMount to the allowed list |
| policies.restrict-proc-mount.parameters.allowedValues | list | `["Default"]` | List of allowed proc mount values Defaults pulled from https://kubernetes.io/docs/concepts/security/pod-security-standards |
| policies.restrict-seccomp | object | `{"enabled":true,"parameters":{"allowedValues":["RuntimeDefault","Localhost"]},"validationFailureAction":"audit"}` | Restrict the seccomp profiles that containers can use to the allowed list |
| policies.restrict-seccomp.parameters.allowedValues | list | `["RuntimeDefault","Localhost"]` | List of allowed seccomp profiles Defaults pulled from https://kubernetes.io/docs/concepts/security/pod-security-standards/#restricted |
| policies.restrict-selinux | object | `{"enabled":true,"parameters":{"allowedValues":["container_t","container_init_t","container_kvm_t"]},"validationFailureAction":"enforce"}` | Restrict the use of any SELinux options.  Only `level` and `type` are allowed.  `Type` must be in the allowed list |
| policies.restrict-selinux.parameters.allowedValues | list | `["container_t","container_init_t","container_kvm_t"]` | List of allowed values for the `type` field Defaults pulled from https://kubernetes.io/docs/concepts/security/pod-security-standards |
| policies.restrict-sysctls | object | `{"enabled":true,"parameters":{"allowedValues":["kernel.shm_rmid_forced","net.ipv4.ip_local_port_range","net.ipv4.ip_unprivileged_port_start","net.ipv4.tcp_syncookies","net.ipv4.ping_group_range"]},"validationFailureAction":"enforce"}` | Restrict allowed sysctls to only items in the allowed list |
| policies.restrict-sysctls.parameters.allowedValues | list | `["kernel.shm_rmid_forced","net.ipv4.ip_local_port_range","net.ipv4.ip_unprivileged_port_start","net.ipv4.tcp_syncookies","net.ipv4.ping_group_range"]` | List of allowed sysctls. Defaults pulled from https://kubernetes.io/docs/concepts/security/pod-security-standards |
| policies.restrict-user-id | object | `{"enabled":true,"parameters":{"allowedValues":[">=1000"]},"validationFailureAction":"audit"}` | Restrict container user IDs to allowed ranges NOTE: Using require-non-root-user will force runAsUser to be defined |
| policies.restrict-user-id.parameters.allowedValues | list | `[">=1000"]` | Allowed user IDs / ranges.  The following operators are valid: >, <, >=, <=, !, |, &. For a lower and upper limit, use ">=min & <=max" |
| policies.restrict-volume-types | object | `{"enabled":true,"parameters":{"allowedValues":["configMap","csi","downwardAPI","emptyDir","ephemeral","persistentVolumeClaim","projected","secret"]},"validationFailureAction":"enforce"}` | Restrict the volume types allowed in containers |
| policies.restrict-volume-types.parameters.allowedValues | list | `["configMap","csi","downwardAPI","emptyDir","ephemeral","persistentVolumeClaim","projected","secret"]` | List of allowed Volume types Defaults pulled from https://kubernetes.io/docs/concepts/security/pod-security-standards/#restricted |
| policies.verify-image | object | `{"enabled":false,"validationFailureAction":"audit"}` | *NEW: |
| additionalPolicies.samplePolicy | object | `{"annotations":{"policies.kyverno.io/category":"Examples","policies.kyverno.io/description":"This sample policy blocks pods from deploying into the 'default' namespace.","policies.kyverno.io/severity":"low","policies.kyverno.io/subject":"Pod","policies.kyverno.io/title":"Sample Policy"},"enabled":false,"kind":"ClusterPolicy","namespace":"","spec":{"rules":[{"match":{"any":[{"resources":{"kinds":["Pods"]}}]},"name":"sample-rule","validate":{"message":"Using 'default' namespace is not allowed.","pattern":{"metadata":{"namespace":"!default"}}}}]}}` | Name of the policy.  Addtional policies can be added by adding a key. |
| additionalPolicies.samplePolicy.enabled | bool | `false` | Controls policy deployment |
| additionalPolicies.samplePolicy.kind | string | `"ClusterPolicy"` | Kind of policy.  Currently, "ClusterPolicy" and "Policy" are supported. |
| additionalPolicies.samplePolicy.namespace | string | `""` | If kind is "Policy", which namespace to target.  The namespace must already exist. |
| additionalPolicies.samplePolicy.annotations | object | `{"policies.kyverno.io/category":"Examples","policies.kyverno.io/description":"This sample policy blocks pods from deploying into the 'default' namespace.","policies.kyverno.io/severity":"low","policies.kyverno.io/subject":"Pod","policies.kyverno.io/title":"Sample Policy"}` | Policy annotations to add |
| additionalPolicies.samplePolicy.annotations."policies.kyverno.io/title" | string | `"Sample Policy"` | Human readable name of policy |
| additionalPolicies.samplePolicy.annotations."policies.kyverno.io/category" | string | `"Examples"` | Category of policy.  Arbitrary. |
| additionalPolicies.samplePolicy.annotations."policies.kyverno.io/severity" | string | `"low"` | Severity of policy if a violation occurs.  Choose "critical", "high", "medium", "low". |
| additionalPolicies.samplePolicy.annotations."policies.kyverno.io/subject" | string | `"Pod"` | Type of resource policy applies to (e.g. Pod, Service, Namespace) |
| additionalPolicies.samplePolicy.annotations."policies.kyverno.io/description" | string | `"This sample policy blocks pods from deploying into the 'default' namespace."` | Description of what the policy does, why it is important, and what items are allowed or unallowed. |
| additionalPolicies.samplePolicy.spec | object | `{"rules":[{"match":{"any":[{"resources":{"kinds":["Pods"]}}]},"name":"sample-rule","validate":{"message":"Using 'default' namespace is not allowed.","pattern":{"metadata":{"namespace":"!default"}}}}]}` | Policy specification.  See `kubectl explain clusterpolicies.spec` |
| additionalPolicies.samplePolicy.spec.rules | list | `[{"match":{"any":[{"resources":{"kinds":["Pods"]}}]},"name":"sample-rule","validate":{"message":"Using 'default' namespace is not allowed.","pattern":{"metadata":{"namespace":"!default"}}}}]` | Policy rules.  At least one is required |
| bbtests.enabled | bool | `false` |  |
| bbtests.scripts.image | string | `"registry1.dso.mil/ironbank/opensource/kubernetes-1.21/kubectl:v1.21.5"` |  |
| bbtests.scripts.envs.ENABLED_POLICIES | string | `"{{ $p := list }}{{ range $k, $v := .Values.policies }}{{ if $v.enabled }}{{ $p = append $p $k }}{{ end }}{{ end }}{{ join \" \" $p }}"` |  |
| bbtests.scripts.envs.IMAGE_PULL_SECRET | string | `"{{ .Values.bbtests.imagePullSecret }}"` |  |
| bbtests.scripts.additionalVolumeMounts[0].name | string | `"kyverno-policies-bbtest-manifests"` |  |
| bbtests.scripts.additionalVolumeMounts[0].mountPath | string | `"/yaml"` |  |
| bbtests.scripts.additionalVolumeMounts[1].name | string | `"kyverno-policies-bbtest-kube-cache"` |  |
| bbtests.scripts.additionalVolumeMounts[1].mountPath | string | `"/.kube/cache"` |  |
| bbtests.scripts.additionalVolumes[0].name | string | `"kyverno-policies-bbtest-manifests"` |  |
| bbtests.scripts.additionalVolumes[0].configMap.name | string | `"kyverno-policies-bbtest-manifests"` |  |
| bbtests.scripts.additionalVolumes[1].name | string | `"kyverno-policies-bbtest-kube-cache"` |  |
| bbtests.scripts.additionalVolumes[1].emptyDir | object | `{}` |  |
| bbtests.imagePullSecret | string | `"private-registry"` |  |

## Contributing

Please see the [contributing guide](./CONTRIBUTING.md) if you are interested in contributing.
