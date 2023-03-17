# mattermost

![Version: 7.7.1-bb.0](https://img.shields.io/badge/Version-7.7.1--bb.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 7.7.1](https://img.shields.io/badge/AppVersion-7.7.1-informational?style=flat-square)

Deployment of mattermost

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
helm install mattermost chart/
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| hostname | string | `"bigbang.dev"` |  |
| istio.enabled | bool | `false` | Toggle istio integration |
| istio.chat.enabled | bool | `true` |  |
| istio.chat.annotations | object | `{}` |  |
| istio.chat.labels | object | `{}` |  |
| istio.chat.gateways[0] | string | `"istio-system/main"` |  |
| istio.chat.hosts[0] | string | `"chat.{{ .Values.hostname }}"` |  |
| istio.injection | string | `"disabled"` |  |
| ingress | object | `{"annotations":{},"enabled":false,"host":"","tlsSecret":""}` | Specification to configure an Ingress with Mattermost |
| monitoring.enabled | bool | `false` |  |
| monitoring.namespace | string | `"monitoring"` |  |
| networkPolicies.enabled | bool | `false` |  |
| networkPolicies.ingressLabels.app | string | `"istio-ingressgateway"` |  |
| networkPolicies.ingressLabels.istio | string | `"ingressgateway"` |  |
| networkPolicies.controlPlaneCidr | string | `"0.0.0.0/0"` |  |
| sso.enabled | bool | `false` |  |
| sso.client_id | string | `"platform1_a8604cc9-f5e9-4656-802d-d05624370245_bb8-mattermost"` |  |
| sso.client_secret | string | `"nothing"` |  |
| sso.auth_endpoint | string | `"https://login.dso.mil/auth/realms/baby-yoda/protocol/openid-connect/auth"` |  |
| sso.token_endpoint | string | `"https://login.dso.mil/auth/realms/baby-yoda/protocol/openid-connect/token"` |  |
| sso.user_api_endpoint | string | `"https://login.dso.mil/auth/realms/baby-yoda/protocol/openid-connect/userinfo"` |  |
| image.name | string | `"registry1.dso.mil/ironbank/opensource/mattermost/mattermost"` |  |
| image.tag | string | `"7.7.1"` |  |
| image.imagePullPolicy | string | `"IfNotPresent"` |  |
| global.imagePullSecrets[0].name | string | `"private-registry"` |  |
| replicaCount | int | `1` |  |
| users | string | `nil` |  |
| enterprise.enabled | bool | `false` |  |
| enterprise.license | string | `""` |  |
| nameOverride | string | `""` |  |
| updateJob.disabled | bool | `true` | Must be disabled when Istio injected |
| updateJob.labels | object | `{}` |  |
| updateJob.annotations | object | `{}` |  |
| resources.limits.cpu | int | `2` |  |
| resources.limits.memory | string | `"4Gi"` |  |
| resources.requests.cpu | int | `2` |  |
| resources.requests.memory | string | `"4Gi"` |  |
| affinity | object | `{}` |  |
| nodeSelector | object | `{}` |  |
| tolerations | object | `{}` |  |
| mattermostEnvs | object | `{}` |  |
| existingSecretEnvs | object | `{}` |  |
| volumes | object | `{}` |  |
| volumeMounts | object | `{}` |  |
| podLabels | object | `{}` | Pod labels for Mattermost server pods |
| podAnnotations | object | `{}` | Pod annotations for Mattermost server pods |
| securityContext | object | `{}` | securityContext for Mattermost server pods |
| containerSecurityContext | object | `{"capabilities":{"drop":["ALL"]}}` | containerSecurityContext for Mattermost server containers |
| minio.install | bool | `false` |  |
| minio.bucketCreationImage | string | `"registry1.dso.mil/ironbank/opensource/minio/mc:RELEASE.2022-08-23T05-45-20Z"` |  |
| minio.service.nameOverride | string | `"minio.mattermost.svc.cluster.local"` |  |
| minio.secrets.name | string | `"mattermost-objstore-creds"` |  |
| minio.secrets.accessKey | string | `"minio"` |  |
| minio.secrets.secretKey | string | `"minio123"` |  |
| minio.tenant.metrics.enabled | bool | `false` |  |
| minio.tenant.metrics.port | int | `9000` |  |
| minio.containerSecurityContext.capabilities.drop[0] | string | `"ALL"` |  |
| postgresql.install | bool | `false` |  |
| postgresql.image.registry | string | `"registry1.dso.mil/ironbank"` |  |
| postgresql.image.repository | string | `"opensource/postgres/postgresql11"` |  |
| postgresql.image.tag | string | `"11.18-1"` |  |
| postgresql.image.pullSecrets[0] | string | `"private-registry"` |  |
| postgresql.postgresqlUsername | string | `"mattermost"` |  |
| postgresql.postgresqlPassword | string | `"bigbang"` |  |
| postgresql.postgresqlDatabase | string | `"mattermost"` |  |
| postgresql.fullnameOverride | string | `"mattermost-postgresql"` |  |
| postgresql.securityContext.fsGroup | int | `26` |  |
| postgresql.containerSecurityContext.runAsUser | int | `26` |  |
| postgresql.containerSecurityContext.capabilities.drop[0] | string | `"ALL"` |  |
| postgresql.volumePermissions.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| postgresql.postgresqlConfiguration.listen_addresses | string | `"*"` |  |
| postgresql.pgHbaConfiguration | string | `"local all all md5\nhost all all all md5"` |  |
| database.secret | string | `""` |  |
| database.readinessCheck.disableDefault | bool | `true` |  |
| database.readinessCheck.image | string | `"registry1.dso.mil/ironbank/opensource/postgres/postgresql12:12.13"` |  |
| database.readinessCheck.command[0] | string | `"/bin/sh"` |  |
| database.readinessCheck.command[1] | string | `"-c"` |  |
| database.readinessCheck.command[2] | string | `"until pg_isready --dbname=\"$DB_CONNECTION_CHECK_URL\"; do echo waiting for database; sleep 5; done;"` |  |
| database.readinessCheck.env[0].name | string | `"DB_CONNECTION_CHECK_URL"` |  |
| database.readinessCheck.env[0].valueFrom.secretKeyRef.key | string | `"DB_CONNECTION_CHECK_URL"` |  |
| database.readinessCheck.env[0].valueFrom.secretKeyRef.name | string | `"{{ .Values.database.secret \| default (printf \"%s-dbcreds\" (include \"mattermost.fullname\" .)) }}"` |  |
| fileStore.secret | string | `""` |  |
| fileStore.url | string | `""` |  |
| fileStore.bucket | string | `""` |  |
| elasticsearch.enabled | bool | `false` |  |
| elasticsearch.connectionurl | string | `"https://logging-ek-es-http.logging.svc.cluster.local:9200"` |  |
| elasticsearch.username | string | `""` |  |
| elasticsearch.password | string | `""` |  |
| elasticsearch.enableindexing | bool | `true` |  |
| elasticsearch.indexprefix | string | `"mm-"` |  |
| elasticsearch.skiptlsverification | bool | `true` |  |
| elasticsearch.bulkindexingtimewindowseconds | int | `3600` |  |
| elasticsearch.sniff | bool | `false` |  |
| elasticsearch.enablesearching | bool | `true` |  |
| elasticsearch.enableautocomplete | bool | `true` |  |
| openshift | bool | `false` |  |
| resourcePatch | object | `{}` |  |
| bbtests.enabled | bool | `false` |  |
| bbtests.cypress.artifacts | bool | `true` |  |
| bbtests.cypress.envs.cypress_url | string | `"http://mattermost.mattermost.svc.cluster.local:8065"` |  |
| bbtests.cypress.envs.cypress_mm_email | string | `"test@bigbang.dev"` |  |
| bbtests.cypress.envs.cypress_mm_user | string | `"bigbang"` |  |
| bbtests.cypress.envs.cypress_mm_password | string | `"Bigbang#123"` |  |

## Contributing

Please see the [contributing guide](./CONTRIBUTING.md) if you are interested in contributing.
