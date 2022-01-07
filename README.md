# kyverno-policies

![Version: 1.0.0-bb.1](https://img.shields.io/badge/Version-1.0.0--bb.1-informational?style=flat-square)

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
| policies.cve-2021-44228 | object | `{"enabled":false}` | Mitigates log4j2 vulnerability (CVE-2021-44228) for library versions >= 2.10 |
| policies.disallow-cri-sock-mount | object | `{"enabled":false,"validationFailureAction":"audit"}` | *NEW: |
| policies.disallow-default-namespace | object | `{"enabled":true,"validationFailureAction":"audit"}` | Prevents deployment of pods into the default namespace |
| policies.disallow-deprecated-apis | object | `{"enabled":true,"validationFailureAction":"audit"}` | Checks for resource APIs in use that will be removed in Kubernetes 1.22 or 1.25 |
| policies.disallow-helm-tiller | object | `{"enabled":false,"validationFailureAction":"audit"}` | *NEW: |
| policies.disallow-host-namespaces | object | `{"enabled":true,"validationFailureAction":"enforce"}` | Disallow use of the host namespace (PID, IPC, Network) by pods |
| policies.disallow-host-path | object | `{"enabled":false,"validationFailureAction":"enforce"}` | *Disallow volumes that mount host paths |
| policies.disallow-host-ports | object | `{"enabled":false,"parameters":{},"validationFailureAction":"enforce"}` | *Disallow containers using host ports |
| policies.disallow-localhost-services | object | `{"enabled":false,"validationFailureAction":"audit"}` | *NEW: |
| policies.disallow-privilege-escalation | object | `{"enabled":true,"validationFailureAction":"audit"}` | Disallows pods that allow privilege escalation |
| policies.disallow-privileged-containers | object | `{"enabled":true,"validationFailureAction":"enforce"}` | Disallow containers that run as privileged |
| policies.disallow-proc-mount | object | `{"enabled":false,"validationFailureAction":"enforce"}` | *Disallow containers that use 'unmasked' for procMount |
| policies.disallow-secrets-form-env-vars | object | `{"enabled":false,"validationFailureAction":"audit"}` | *NEW: |
| policies.disallow-selinux | object | `{"enabled":false,"parameters":{},"validationFailureAction":"enforce"}` | *Disallow the use of any SELinux options |
| policies.ensure-readonly-hostpath | object | `{"enabled":false,"validationFailureAction":"audit"}` | *NEW: |
| policies.limit-hostpath-vols | object | `{"enabled":false,"validationFailureAction":"audit"}` | *NEW: |
| policies.memory-requests-equal-limits | object | `{"enabled":false,"validationFailureAction":"audit"}` | *Enforce guaranteed quality of service by requiring pods to set CPU and memory requests equal to limits |
| policies.replace-image-registry | object | `{"enabled":false,"parameters":{"replacements":[]}}` | Replaces an existing image registry with a new registry in containers (e.g. proxy) |
| policies.replace-image-registry.parameters.replacements | list | `[]` | List of registries to replace |
| policies.require-drop-all | object | `{"enabled":false,"validationFailureAction":"audit"}` | *Requires all containers to drop all Linux capabilities |
| policies.require-labels | object | `{"enabled":false,"parameters":{},"validationFailureAction":"audit"}` | *Require specified labels to be on all pods |
| policies.require-pod-requests-limits | object | `{"enabled":false,"validationFailureAction":"audit"}` | *Require all pods have CPU and memory requests and limits specified |
| policies.require-probes | object | `{"enabled":false,"parameters":{},"validationFailureAction":"audit"}` | *Require specified probes and probe types on pods |
| policies.require-ro-rootfs | object | `{"enabled":false,"validationFailureAction":"audit"}` | *Require containers set root filesystem to readonly |
| policies.require-run-as-nonroot | object | `{"enabled":false,"validationFailureAction":"audit"}` | *Disallow containers that attempt to run as root |
| policies.restrict-apparmor-profiles | object | `{"enabled":false,"parameters":{},"validationFailureAction":"audit"}` | *Restricts pods that use AppArmor to specified profiles Iron Bank containers are either distroless or RHEL UBI.  Neither of these uses AppArmor |
| policies.restrict-automount-sa-token | object | `{"enabled":false,"validationFailureAction":"audit"}` | *Disallow pods from automatically mounting the default service account |
| policies.restrict-capabilities | object | `{"enabled":true,"parameters":{"allowedCapabilities":[]},"validationFailureAction":"audit"}` | *Disallow containers adding capabilities that are not specified |
| policies.restrict-capabilities.parameters.allowedCapabilities | list | `[]` | List of capabilities that are allowed to be added |
| policies.restrict-controlplane-scheduling | object | `{"enabled":false,"validationFailureAction":"audit"}` | *NEW |
| policies.restrict-image-registries | object | `{"enabled":false,"parameters":{},"validationFailureAction":"enforce"}` | *Restricts container images to specified registries |
| policies.restrict-image-tags | object | `{"enabled":true,"parameters":{"disallowedTags":["latest"]},"validationFailureAction":"enforce"}` | Restricts container image tags based on blacklist |
| policies.restrict-node-port | object | `{"enabled":false,"validationFailureAction":"audit"}` | *Disallow services that use NodePorts |
| policies.restrict-seccomp | object | `{"enabled":false,"parameters":{},"validationFailureAction":"audit"}` | *Restrict the seccomp profiles that containers can use |
| policies.restrict-service-external-ips | object | `{"enabled":false,"parameters":{},"validationFailureAction":"enforce"}` | *Restrict services to use specified external IPs |
| policies.restrict-sysctls | object | `{"enabled":false,"parameters":{},"validationFailureAction":"enforce"}` | *Restrict allowed sysctls to only those specified |
| policies.restrict-usergroup-fsgroup-id | object | `{"enabled":false,"parameters":{},"validationFailureAction":"audit"}` | *Limit allowed IDs for users and groups in containers |
| policies.restrict-volume-types | object | `{"enabled":false,"parameters":{},"validationFailureAction":"enforce"}` | *Restrict the volume types allowd in containers |
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
