# flux-podinfo

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 6.0.0](https://img.shields.io/badge/AppVersion-6.0.0-informational?style=flat-square)

Flux compatible Helm chart for podinfo

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
helm install flux-podinfo chart/
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| podinfo.enabled | bool | `true` |  |
| podinfo.git.repo | string | `"https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/podinfo"` |  |
| podinfo.git.tag | string | `"6.0.0-bb.1"` |  |
| podinfo.git.path | string | `"chart"` |  |
| podinfo.flux | object | `{}` |  |
| podinfo.ingress.gateway | string | `""` |  |
| networkPolicies.enabled | bool | `false` |  |

## Contributing

Please see the [contributing guide](./CONTRIBUTING.md) if you are interested in contributing.
# podinfo

![Version: 6.0.0-bb.4](https://img.shields.io/badge/Version-6.0.0--bb.4-informational?style=flat-square) ![AppVersion: 6.0.0](https://img.shields.io/badge/AppVersion-6.0.0-informational?style=flat-square)

Podinfo Helm chart for Kubernetes

## Upstream References
* <https://github.com/stefanprodan/podinfo>

* <https://github.com/stefanprodan/podinfo>

## Learn More
* [Application Overview](docs/overview.md)
* [Other Documentation](docs/)

## Pre-Requisites

* Kubernetes Cluster deployed
* Kubernetes config installed in `~/.kube/config`
* Helm installed

Kubernetes: `>=1.19.0-0`

Install Helm

https://helm.sh/docs/intro/install/

## Deployment

* Clone down the repository
* cd into directory
```bash
helm install podinfo chart/
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| replicaCount | int | `1` |  |
| logLevel | string | `"info"` |  |
| host | string | `nil` |  |
| backend | string | `nil` |  |
| backends | list | `[]` |  |
| image.repository | string | `"registry.dso.mil/platform-one/big-bang/apps/sandbox/podinfo/podinfo"` |  |
| image.tag | string | `"6.0.0"` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| ui.color | string | `"#34577c"` |  |
| ui.message | string | `""` |  |
| ui.logo | string | `""` |  |
| faults.delay | bool | `false` |  |
| faults.error | bool | `false` |  |
| faults.unhealthy | bool | `false` |  |
| faults.unready | bool | `false` |  |
| faults.testFail | bool | `false` |  |
| faults.testTimeout | bool | `false` |  |
| service.enabled | bool | `true` |  |
| service.annotations | object | `{}` |  |
| service.type | string | `"ClusterIP"` |  |
| service.metricsPort | int | `9797` |  |
| service.httpPort | int | `9898` |  |
| service.externalPort | int | `9898` |  |
| service.grpcPort | int | `9999` |  |
| service.grpcService | string | `"podinfo"` |  |
| service.nodePort | int | `31198` |  |
| service.hostPort | string | `nil` |  |
| h2c.enabled | bool | `false` |  |
| tls.enabled | bool | `false` |  |
| tls.secretName | string | `nil` |  |
| tls.certPath | string | `"/data/cert"` |  |
| tls.port | int | `9899` |  |
| tls.hostPort | string | `nil` |  |
| certificate.create | bool | `false` |  |
| certificate.issuerRef.kind | string | `"ClusterIssuer"` |  |
| certificate.issuerRef.name | string | `"self-signed"` |  |
| certificate.dnsNames[0] | string | `"podinfo"` |  |
| hpa.enabled | bool | `false` |  |
| hpa.maxReplicas | int | `10` |  |
| hpa.cpu | string | `nil` |  |
| hpa.memory | string | `nil` |  |
| hpa.requests | string | `nil` |  |
| cache | string | `""` |  |
| redis.enabled | bool | `false` |  |
| redis.repository | string | `"redis"` |  |
| redis.tag | string | `"6.0.8"` |  |
| serviceAccount.enabled | bool | `false` |  |
| serviceAccount.name | string | `nil` |  |
| serviceAccount.imagePullSecrets | list | `[]` |  |
| securityContext | object | `{}` |  |
| ingress.enabled | bool | `false` |  |
| ingress.className | string | `""` |  |
| ingress.annotations | object | `{}` |  |
| ingress.hosts[0].host | string | `"podinfo.local"` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| ingress.tls | list | `[]` |  |
| linkerd.profile.enabled | bool | `false` |  |
| serviceMonitor.enabled | bool | `false` |  |
| serviceMonitor.interval | string | `"15s"` |  |
| serviceMonitor.additionalLabels | object | `{}` |  |
| serviceMonitor.dashboards.namespace | string | `""` |  |
| serviceMonitor.dashboards.label | string | `"grafana_dashboard"` |  |
| resources.limits | string | `nil` |  |
| resources.requests.cpu | string | `"1m"` |  |
| resources.requests.memory | string | `"16Mi"` |  |
| nodeSelector | object | `{}` |  |
| tolerations | list | `[]` |  |
| affinity | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| domain | string | `"bigbang.dev"` |  |
| istio.enabled | bool | `false` |  |
| istio.podinfo.enabled | bool | `true` |  |
| istio.podinfo.gateways[0] | string | `"istio-system/public"` |  |
| istio.podinfo.hosts[0] | string | `"podinfo.{{ .Values.domain }}"` |  |

## Contributing

Please see the [contributing guide](./CONTRIBUTING.md) if you are interested in contributing.
