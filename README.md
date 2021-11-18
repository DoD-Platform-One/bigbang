# nexus-repository-manager

![Version: 34.1.0-bb.5](https://img.shields.io/badge/Version-34.1.0--bb.5-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 3.34.1](https://img.shields.io/badge/AppVersion-3.34.1-informational?style=flat-square)

Sonatype Nexus Repository Manager - Universal Binary repository

## Upstream References
* <https://www.sonatype.com/nexus-repository-oss>

* <https://github.com/sonatype/nexus-public>

## Learn More
* [Application Overview](docs/overview.md)
* [Other Documentation](docs/)

## Pre-Requisites

* Kubernetes Cluster deployed
* Kubernetes config installed in `~/.kube/config`
* Helm installed

Install Helm

https://helm.sh/docs/intro/install/

## Deployment

* Clone down the repository
* cd into directory
```bash
helm install nexus-repository-manager chart/
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| hostname | string | `"nexus"` | Big Bang Additions |
| domain | string | `"bigbang.dev"` |  |
| istio.enabled | bool | `false` |  |
| istio.nexus.gateways[0] | string | `"istio-system/main"` |  |
| networkPolicies.enabled | bool | `false` |  |
| networkPolicies.ingressLabels.app | string | `"istio-ingressgateway"` |  |
| networkPolicies.ingressLabels.istio | string | `"ingressgateway"` |  |
| monitoring.enabled | bool | `false` |  |
| license_key | string | `""` |  |
| license.mountPath | string | `"/nexus-data/sonatype-license.lic"` |  |
| license.subPath | string | `"sonatype-license.lic"` |  |
| sso.enabled | bool | `false` |  |
| sso.idp_data.entityId | string | `""` |  |
| sso.idp_data.usernameAttribute | string | `""` |  |
| sso.idp_data.firstNameAttribute | string | `""` |  |
| sso.idp_data.lastNameAttribute | string | `""` |  |
| sso.idp_data.emailAttribute | string | `""` |  |
| sso.idp_data.groupsAttribute | string | `""` |  |
| sso.idp_data.validateResponseSignature | bool | `true` |  |
| sso.idp_data.validateAssertionSignature | bool | `true` |  |
| sso.idp_data.idpMetadata | string | `""` |  |
| sso.realm[0] | string | `"NexusAuthenticatingRealm"` |  |
| sso.realm[1] | string | `"NexusAuthorizingRealm"` |  |
| sso.realm[2] | string | `"SamlRealm"` |  |
| sso.role[0].id | string | `"nexus"` |  |
| sso.role[0].name | string | `"nexus"` |  |
| sso.role[0].description | string | `"nexus group"` |  |
| sso.role[0].privileges[0] | string | `"nx-all"` |  |
| sso.role[0].roles[0] | string | `"nx-admin"` |  |
| proxy.enabled | bool | `false` |  |
| proxy.request.tid | int | `1` |  |
| proxy.request.action | string | `"coreui_HttpSettings"` |  |
| proxy.request.method | string | `"update"` |  |
| proxy.request.type | string | `"rpc"` |  |
| proxy.request.data[0].userAgentSuffix | string | `nil` |  |
| proxy.request.data[0].timeout | string | `nil` |  |
| proxy.request.data[0].retries | string | `nil` |  |
| proxy.request.data[0].httpEnabled | bool | `false` |  |
| proxy.request.data[0].httpHost | string | `nil` |  |
| proxy.request.data[0].httpPort | string | `nil` |  |
| proxy.request.data[0].httpAuthEnabled | string | `nil` |  |
| proxy.request.data[0].httpAuthUsername | string | `nil` |  |
| proxy.request.data[0].httpAuthPassword | string | `nil` |  |
| proxy.request.data[0].httpAuthNtlmHost | string | `nil` |  |
| proxy.request.data[0].httpAuthNtlmDomain | string | `nil` |  |
| proxy.request.data[0].httpsEnabled | bool | `false` |  |
| proxy.request.data[0].httpsHost | string | `nil` |  |
| proxy.request.data[0].httpsPort | string | `nil` |  |
| proxy.request.data[0].httpsAuthEnabled | string | `nil` |  |
| proxy.request.data[0].httpsAuthUsername | string | `nil` |  |
| proxy.request.data[0].httpsAuthPassword | string | `nil` |  |
| proxy.request.data[0].httpsAuthNtlmHost | string | `nil` |  |
| proxy.request.data[0].httpsAuthNtlmDomain | string | `nil` |  |
| proxy.request.data[0].nonProxyHosts | list | `[]` |  |
| job_image.repository | string | `"registry1.dso.mil/ironbank/redhat/ubi/ubi8-minimal"` |  |
| job_image.tag | float | `8.4` |  |
| job_image.pullPolicy | string | `"IfNotPresent"` |  |
| ingress | object | `{"annotations":{"kubernetes.io/ingress.class":"nginx"},"enabled":false,"hostPath":"/","hostRepo":"repo.demo","tls":[]}` | End of BigBang Additions |
| statefulset.enabled | bool | `false` |  |
| deploymentStrategy | string | `"Recreate"` |  |
| image.repository | string | `"registry1.dso.mil/ironbank/sonatype/nexus/nexus"` |  |
| image.tag | string | `"3.34.1-01"` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| nexus.extraLabels.app | string | `"nexus-repository-manager"` |  |
| nexus.docker.enabled | bool | `false` |  |
| nexus.docker.registries | list | `[]` |  |
| nexus.env[0].name | string | `"install4jAddVmParams"` |  |
| nexus.env[0].value | string | `"-Xms2703M -Xmx2703M -XX:MaxDirectMemorySize=2703G -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap"` |  |
| nexus.env[1].name | string | `"NEXUS_SECURITY_RANDOMPASSWORD"` |  |
| nexus.env[1].value | string | `"true"` |  |
| nexus.properties.override | bool | `false` |  |
| nexus.properties.data | object | `{}` |  |
| nexus.repository.enabled | bool | `false` |  |
| nexus.repository.repo[0].name | string | `"test-nexus"` |  |
| nexus.repository.repo[0].format | string | `"raw"` |  |
| nexus.repository.repo[0].type | string | `"hosted"` |  |
| nexus.repository.repo[0].repo_data.name | string | `"test-nexus"` |  |
| nexus.repository.repo[0].repo_data.online | bool | `true` |  |
| nexus.repository.repo[0].repo_data.storage.blobStoreName | string | `"default"` |  |
| nexus.repository.repo[0].repo_data.storage.strictContentTypeValidation | bool | `true` |  |
| nexus.repository.repo[0].repo_data.storage.writePolicy | string | `"allow_once"` |  |
| nexus.repository.repo[0].repo_data.cleanup.policyNames[0] | string | `"string"` |  |
| nexus.repository.repo[0].repo_data.component.proprietaryComponents | bool | `true` |  |
| nexus.repository.repo[0].repo_data.raw.contentDisposition | string | `"ATTACHMENT"` |  |
| nexus.affinity | object | `{}` |  |
| nexus.resources.requests.cpu | int | `4` |  |
| nexus.resources.requests.memory | string | `"8000Mi"` |  |
| nexus.resources.limits.cpu | int | `4` |  |
| nexus.resources.limits.memory | string | `"8000Mi"` |  |
| nexus.nexusPort | int | `8081` |  |
| nexus.securityContext.fsGroup | int | `2000` |  |
| nexus.podAnnotations | object | `{}` |  |
| nexus.livenessProbe.initialDelaySeconds | int | `30` |  |
| nexus.livenessProbe.periodSeconds | int | `30` |  |
| nexus.livenessProbe.failureThreshold | int | `6` |  |
| nexus.livenessProbe.timeoutSeconds | int | `10` |  |
| nexus.livenessProbe.path | string | `"/"` |  |
| nexus.readinessProbe.initialDelaySeconds | int | `30` |  |
| nexus.readinessProbe.periodSeconds | int | `30` |  |
| nexus.readinessProbe.failureThreshold | int | `6` |  |
| nexus.readinessProbe.timeoutSeconds | int | `10` |  |
| nexus.readinessProbe.path | string | `"/"` |  |
| nexus.hostAliases | list | `[]` |  |
| nexus.imagePullSecrets[0].name | string | `"private-registry"` |  |
| nameOverride | string | `""` |  |
| fullnameOverride | string | `""` |  |
| deployment.annotations | object | `{}` |  |
| deployment.initContainers | string | `nil` |  |
| deployment.postStart.command | string | `nil` |  |
| deployment.preStart.command | string | `nil` |  |
| deployment.terminationGracePeriodSeconds | int | `120` |  |
| deployment.additionalContainers | string | `nil` |  |
| deployment.additionalVolumes | string | `nil` |  |
| deployment.additionalVolumeMounts | string | `nil` |  |
| service.name | string | `"nexus3"` |  |
| service.enabled | bool | `true` |  |
| service.labels | object | `{}` |  |
| service.annotations | object | `{}` |  |
| service.type | string | `"ClusterIP"` |  |
| route.enabled | bool | `false` |  |
| route.name | string | `"docker"` |  |
| route.portName | string | `"docker"` |  |
| route.labels | string | `nil` |  |
| route.annotations | string | `nil` |  |
| nexusProxyRoute.enabled | bool | `false` |  |
| nexusProxyRoute.labels | string | `nil` |  |
| nexusProxyRoute.annotations | string | `nil` |  |
| persistence.enabled | bool | `true` |  |
| persistence.accessMode | string | `"ReadWriteOnce"` |  |
| persistence.storageSize | string | `"8Gi"` |  |
| tolerations | list | `[]` |  |
| config.enabled | bool | `false` |  |
| config.mountPath | string | `"/sonatype-nexus-conf"` |  |
| config.data | list | `[]` |  |
| secret.enabled | bool | `true` |  |
| secret.mountPath | string | `"/nexus-data/admin.password"` |  |
| secret.subPath | string | `"admin.password"` |  |
| secret.readOnly | bool | `true` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.name | string | `""` |  |
| psp.create | bool | `false` |  |
| psp.openshift | bool | `false` |  |

## Contributing

Please see the [contributing guide](./CONTRIBUTING.md) if you are interested in contributing.
