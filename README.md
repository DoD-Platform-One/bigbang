# mattermost-operator

![Version: 1.18.0-bb.0](https://img.shields.io/badge/Version-1.18.0--bb.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.18.0](https://img.shields.io/badge/AppVersion-1.18.0-informational?style=flat-square)

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
| image.imagePullPolicy | string | `"IfNotPresent"` | Default image pull policy |
| image.repository | string | `"registry1.dso.mil/ironbank/opensource/mattermost/mattermost-operator"` | Full image name |
| image.tag | string | `"v1.18.0"` | Image tag |
| replicas.count | int | `1` | Mattermost operator desired replicas |
| imagePullSecrets | list | `[{"name":"private-registry"}]` | Image pull secrets |
| resources | object | `{"limits":{"cpu":"100m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"512Mi"}}` | Resources for operator pod(s) |
| affinity | object | `{}` | Affinity for operator pod(s) |
| nodeSelector | object | `{}` | Node selector for operator pod(s) |
| tolerations | object | `{}` | Tolerations for operator pod(s) |
| podAnnotations | object | `{}` | Annotations for operator pod(s) |
| networkPolicies.enabled | bool | `false` | Toggle on/off Big Bang provided network policies |
| networkPolicies.controlPlaneCidr | string | `"0.0.0.0/0"` | See `kubectl cluster-info` and then resolve to IP |
| istio.enabled | bool | `false` | Toggle on/off istio interaction, used for network policies and mTLS |
| istio.mtls | object | `{"mode":"STRICT"}` | Default peer authentication |
| istio.mtls.mode | string | `"STRICT"` | STRICT = Allow only mutual TLS traffic, PERMISSIVE = Allow both plain text and mutual TLS traffic |
| monitoring.enabled | bool | `false` | Toggle on/off monitoring interaction, used for network policies |
| openshift | bool | `false` | Openshift feature toggle, used for DNS network policy |

## Contributing

Please see the [contributing guide](./CONTRIBUTING.md) if you are interested in contributing.
