# mattermost-operator

![Version: 1.17.0-bb.2](https://img.shields.io/badge/Version-1.17.0--bb.2-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.17.0](https://img.shields.io/badge/AppVersion-1.17.0-informational?style=flat-square)

Deployment of mattermost operator using Helm

## Upstream References
* <https://github.com/mattermost/mattermost-operator>

## Learn More
* [Application Overview](docs/overview.md)
* [Other Documentation](docs/)

## Pre-Requisites

* Kubernetes Cluster deployed
* Kubernetes config installed in `~/.kube/config`
* Helm installed

Kubernetes: `>=1.12.0-0`

Install Helm

https://helm.sh/docs/intro/install/

## Deployment

* Clone down the repository
* cd into directory
```bash
helm install mattermost-operator chart/
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| image.imagePullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"registry1.dso.mil/ironbank/opensource/mattermost/mattermost-operator"` |  |
| image.tag | string | `"v1.17.0"` |  |
| replicas.count | int | `1` |  |
| imagePullSecrets[0].name | string | `"private-registry"` |  |
| resources.requests.memory | string | `"512Mi"` |  |
| resources.requests.cpu | string | `"100m"` |  |
| resources.limits.memory | string | `"512Mi"` |  |
| resources.limits.cpu | string | `"100m"` |  |
| affinity | object | `{}` |  |
| nodeSelector | object | `{}` |  |
| tolerations | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| networkPolicies.enabled | bool | `false` |  |
| networkPolicies.controlPlaneCidr | string | `"0.0.0.0/0"` |  |
| istio.enabled | bool | `false` |  |
| monitoring.enabled | bool | `false` |  |
| openshift | bool | `false` |  |

## Contributing

Please see the [contributing guide](./CONTRIBUTING.md) if you are interested in contributing.
