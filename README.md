# bigbang

![Version: 1.1.0](https://img.shields.io/badge/Version-1.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

Big Bang is a declarative, continuous delivery tool for core DoD hardened and approved packages into a Kubernetes cluster.

**Homepage:** <https://p1.dso.mil/#/products/big-bang>

Big Bang follows a [GitOps](#gitops) approach to configuration management, using [Flux v2](#flux-v2) to reconcile Git with the cluster.  Environments (e.g. dev, prod) and packages (e.g. istio) can be fully configured to suit the deployment needs.

## Usage

Big Bang is intended to be used for deploying and maintaining a DoD hardened and approved set of packages into a Kubernetes cluster.  Deployment and configuration of ingress/egress, load balancing, policy auditing, logging, monitoring, etc. are handled via Big Bang.   Additional packages (e.g. ArgoCD, GitLab) can also be enabled and customized to extend Big Bang's baseline.  Once deployed, the customer can use the Kubernetes cluster to add mission specific applications.

Additional information can be found in [Big Bang Overview](./docs/1_overview.md).

## Getting Started

To start using Big Bang, you will need to create your own Big Bang environment tailored to your needs.  The [Big Bang customer template](https://repo1.dso.mil/platform-one/big-bang/customers/template/) is provided for you to copy into your own Git repository and begin modifications.  Follow the instructions in [Big Bang Getting Started](./docs/2_getting_started.md) to customize and deploy Big Bang.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Tom Runyon | tom@runyon.dev |  |
| Josh Wolf | josh@rancherfederal.com |  |

## Source Code

* <https://repo1.dso.mil/platform-one/big-bang/bigbang>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| hostname | string | `"bigbang.dev"` | Domain used for BigBang created exposed services, can be overridden by individual packages. |
| offline | bool | `false` | (experimental) Toggle sourcing from external repos. All this does right now is toggle GitRepositories, it is _not_ fully functional |
| registryCredentials | object | `{"email":"","password":"","registry":"registry1.dso.mil","username":""}` | Single set of registry credentials used to pull all images deployed by BigBang. |
| git | object | `{"credentials":{"knownHosts":"","password":"","privateKey":"","publicKey":"","username":""},"existingSecret":""}` | Multiple sets of registry credentials used to pull all images deployed by BigBang. Credentials will only be created when a valid combination exists, registry, username, and password (email is optional) Or a list of registires:  - registry: registry1.dso.mil    username: ""    password: ""    email: ""  - registry: registry.dso.mil    username: ""    password: ""    email: "" -- Git credential settings for accessing private repositories Order of precedence is:   1. existingSecret   2. http credentials (username/password)   3. ssh credentials (privateKey/publicKey/knownHosts) |
| git.existingSecret | string | `""` | Existing secret to use for git credentials, must be in the appropriate format: https://toolkit.fluxcd.io/components/source/gitrepositories/#https-authentication |
| git.credentials | object | `{"knownHosts":"","password":"","privateKey":"","publicKey":"","username":""}` | Chart created secrets with user defined values |
| git.credentials.username | string | `""` | HTTP git credentials, both username and password must be provided |
| git.credentials.privateKey | string | `""` | SSH git credentials, privateKey, publicKey, and knownHosts must be provided |
| sso | object | `{"certificate_authority":"","client_id":"","client_secret":"","jwks":"","oidc":{"host":"login.dso.mil","realm":"baby-yoda"}}` | Global SSO values used for BigBang deployments when sso is enabled, can be overridden by individual packages. |
| sso.oidc.host | string | `"login.dso.mil"` | Domain for keycloak used for configuring SSO |
| sso.oidc.realm | string | `"baby-yoda"` | Keycloak realm containing clients |
| sso.certificate_authority | string | `""` | Keycloak's certificate authority (unencoded) used by authservice to support SSO for various packages |
| sso.jwks | string | `""` | Keycloak realm's json web key uri, obtained through https://<keycloak-server>/auth/realms/<realm>/.well-known/openid-configuration |
| sso.client_id | string | `""` | OIDC client ID used for packages authenticated through authservice |
| sso.client_secret | string | `""` | OIDC client secret used for packages authenticated through authservice |
| flux | object | `{"install":{"retries":3},"interval":"2m","rollback":{"cleanupOnFail":true,"timeout":"10m"},"upgrade":{"retries":3}}` | (Advanced) Flux reconciliation parameters. The default values provided will be sufficient for the majority of workloads. |
| istio.enabled | bool | `true` | Toggle deployment of Istio. |
| istio.git.repo | string | `"https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-controlplane.git"` |  |
| istio.git.path | string | `"./chart"` |  |
| istio.git.tag | string | `"1.7.3-bb.7"` |  |
| istio.ingress | object | `{"cert":"","key":""}` | Certificate/Key pair to use as the default certificate for exposing BigBang created applications. If nothing is provided, applications will expect a valid tls secret to exist in the `istio-system` namespace called `wildcard-cert`. |
| istio.sso.enabled | bool | `false` | Toggle SSO for kiali and jaeger on and off |
| istio.sso.kiali.client_id | string | `""` | OIDC Client ID use for kiali |
| istio.sso.kiali.client_secret | string | `""` | OIDC Client Secret to use for kiali |
| istio.sso.jaeger.client_id | string | `""` | OIDC Client ID to use for jaeger |
| istio.sso.jaeger.client_secret | string | `""` | OIDC Client Secret to use for jaeger |
| istio.values | object | `{}` | Values to passthrough to the istio-controlplane chart: https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-controlplane.git |
| istiooperator.enabled | bool | `true` | Toggle deployment of Istio Operator. |
| istiooperator.git.repo | string | `"https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-operator.git"` |  |
| istiooperator.git.path | string | `"./chart"` |  |
| istiooperator.git.tag | string | `"1.7.0-bb.1"` |  |
| istiooperator.values | object | `{}` | Values to passthrough to the istio-operator chart: https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-operator.git |
| clusterAuditor.enabled | bool | `true` | Toggle deployment of Cluster Auditor. |
| clusterAuditor.git.repo | string | `"https://repo1.dso.mil/platform-one/big-bang/apps/core/cluster-auditor.git"` |  |
| clusterAuditor.git.path | string | `"./chart"` |  |
| clusterAuditor.git.tag | string | `"0.1.8-bb.1"` |  |
| clusterAuditor.values | object | `{}` | Values to passthrough to the cluster auditor chart: https://repo1.dso.mil/platform-one/big-bang/apps/core/cluster-auditor.git |
| gatekeeper.enabled | bool | `true` | Toggle deployment of OPA Gatekeeper. |
| gatekeeper.git.repo | string | `"https://repo1.dso.mil/platform-one/big-bang/apps/core/policy.git"` |  |
| gatekeeper.git.path | string | `"./chart"` |  |
| gatekeeper.git.tag | string | `"3.1.2-bb.3"` |  |
| gatekeeper.values | object | `{}` | Values to passthrough to the gatekeeper chart: https://repo1.dso.mil/platform-one/big-bang/apps/core/policy.git |
| logging.enabled | bool | `true` | Toggle deployment of Logging (EFK). |
| logging.git.repo | string | `"https://repo1.dso.mil/platform-one/big-bang/apps/core/elasticsearch-kibana.git"` |  |
| logging.git.path | string | `"./chart"` |  |
| logging.git.tag | string | `"0.1.4-bb.3"` |  |
| logging.values | object | `{}` | Values to passthrough to the elasticsearch-kibana chart: https://repo1.dso.mil/platform-one/big-bang/apps/core/elasticsearch-kibana.git |
| eckoperator.enabled | bool | `true` | Toggle deployment of ECK Operator. |
| eckoperator.git.repo | string | `"https://repo1.dso.mil/platform-one/big-bang/apps/core/eck-operator.git"` |  |
| eckoperator.git.path | string | `"./chart"` |  |
| eckoperator.git.tag | string | `"1.3.0-bb.3"` |  |
| eckoperator.values | object | `{}` | Values to passthrough to the eck-operator chart: https://repo1.dso.mil/platform-one/big-bang/apps/core/eck-operator.git |
| fluentbit.enabled | bool | `true` | Toggle deployment of Fluent-Bit. |
| fluentbit.git.repo | string | `"https://repo1.dso.mil/platform-one/big-bang/apps/core/fluentbit.git"` |  |
| fluentbit.git.path | string | `"./chart"` |  |
| fluentbit.git.tag | string | `"0.7.5-bb.0"` |  |
| fluentbit.values | object | `{}` |  |
| monitoring.enabled | bool | `true` | Toggle deployment of Monitoring (Prometheus, Grafana, and Alertmanager). |
| monitoring.git.repo | string | `"https://repo1.dso.mil/platform-one/big-bang/apps/core/monitoring.git"` |  |
| monitoring.git.path | string | `"./chart"` |  |
| monitoring.git.tag | string | `"11.0.0-bb.13"` |  |
| monitoring.sso.enabled | bool | `false` | Toggle SSO for monitoring components on and off |
| monitoring.sso.prometheus.client_id | string | `""` | Prometheus OIDC client ID |
| monitoring.sso.prometheus.client_secret | string | `""` | Prometheus OIDC client secret |
| monitoring.sso.alertmanager.client_id | string | `""` | Alertmanager OIDC client ID |
| monitoring.sso.alertmanager.client_secret | string | `""` | Alertmanager OIDC client secret |
| monitoring.sso.grafana.client_id | string | `""` | Grafana OIDC client ID |
| monitoring.sso.grafana.client_secret | string | `""` | Grafana OIDC client secret |
| monitoring.sso.grafana.scopes | string | `""` | Grafana OIDC client scopes, comma separated |
| monitoring.sso.grafana.allow_sign_up | string | `"true"` |  |
| monitoring.sso.grafana.role_attribute_path | string | `"Viewer"` |  |
| monitoring.values | object | `{}` | Values to passthrough to the monitoring chart: https://repo1.dso.mil/platform-one/big-bang/apps/core/monitoring.git |
| twistlock.enabled | bool | `true` | Toggle deployment of Twistlock. |
| twistlock.git.repo | string | `"https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/twistlock.git"` |  |
| twistlock.git.path | string | `"./chart"` |  |
| twistlock.git.tag | string | `"0.0.2-bb.1"` |  |
| twistlock.values | object | `{}` | Values to passthrough to the twistlock chart: https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/twistlock.git |
| minio.enabled | bool | `true` | Toggle deployment of minio operator and instance. |
| minio.miniooperator.git.repo | string | `"https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio-operator.git"` |  |
| minio.miniooperator.git.path | string | `"./chart"` |  |
| minio.miniooperator.git.tag | string | `"2.0.9-bb.1"` |  |
| minio.miniooperator.values | object | `{}` | Values to passthrough to the minio operator chart: https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio-operator.git |
| minio.minioinstance.git.repo | string | `"https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio.git"` |  |
| minio.minioinstance.git.path | string | `"./chart"` |  |
| minio.minioinstance.git.tag | string | `"2.0.9-bb.1"` |  |
| minio.minioinstance.values | object | `{}` | Values to passthrough to the minio instance chart: https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio.git |
| addons.argocd.enabled | bool | `false` | Toggle deployment of ArgoCD. |
| addons.argocd.git.repo | string | `"https://repo1.dso.mil/platform-one/big-bang/apps/core/argocd.git"` |  |
| addons.argocd.git.path | string | `"./chart"` |  |
| addons.argocd.git.tag | string | `"2.9.5-bb.4"` |  |
| addons.argocd.sso.enabled | bool | `false` | Toggle SSO for ArgoCD on and off |
| addons.argocd.sso.client_id | string | `""` | ArgoCD OIDC client ID |
| addons.argocd.sso.client_secret | string | `""` | ArgoCD OIDC client secret |
| addons.argocd.sso.provider_name | string | `""` | ArgoCD SSO login text |
| addons.argocd.sso.groups | string | `"g, Impact Level 2 Authorized, role:admin\n"` | ArgoCD SSO group roles, see docs for more details: https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/ |
| addons.argocd.values | object | `{}` | Values to passthrough to the argocd chart: https://repo1.dso.mil/platform-one/big-bang/apps/core/argocd.git |
| addons.authservice.enabled | bool | `false` | Toggle deployment of Authservice. if enabling authservice, a filter needs to be provided by either enabling sso for monitoring or istio, or manually adding a filter chain in the values here: values:   chain:     minimal:       callback_uri: "https://somecallback" |
| addons.authservice.git.repo | string | `"https://repo1.dso.mil/platform-one/big-bang/apps/core/authservice.git"` |  |
| addons.authservice.git.path | string | `"./chart"` |  |
| addons.authservice.git.tag | string | `"0.1.6-bb.3"` |  |
| addons.authservice.values | object | `{}` | Values to passthrough to the authservice chart: https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/authservice.git |
| addons.authservice.chains | object | `{}` | Additional authservice chain configurations. |
| addons.gitlab.enabled | bool | `false` | Toggle deployment of Gitlab. |
| addons.gitlab.hostnames.gitlab | string | `"gitlab.bigbang.dev"` |  |
| addons.gitlab.hostnames.registry | string | `"registry.bigbang.dev"` |  |
| addons.gitlab.git.repo | string | `"https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab.git"` |  |
| addons.gitlab.git.path | string | `"./chart"` |  |
| addons.gitlab.git.tag | string | `"4.8.0-bb.0"` |  |
| addons.gitlab.sso.enabled | bool | `false` | Toggle OIDC SSO for Gitlab on and off. Enabling this option will auto-create any required secrets. |
| addons.gitlab.sso.client_id | string | `""` | Gitlab OIDC client ID |
| addons.gitlab.sso.client_secret | string | `""` | Gitlab OIDC client secret |
| addons.gitlab.sso.label | string | `""` | Gitlab SSO login button label |
| addons.gitlab.database.host | string | `""` | Hostname of a pre-existing PostgreSQL database to use for Gitlab. Entering connection info will disable the deployment of an internal database and will auto-create any required secrets. |
| addons.gitlab.database.port | int | `5432` | Port of a pre-existing PostgreSQL database to use for Gitlab. |
| addons.gitlab.database.database | string | `""` | Database name to connect to on host. |
| addons.gitlab.database.username | string | `""` | Username to connect as to external database, the user must have all privileges on the database. |
| addons.gitlab.database.password | string | `""` | Database password for the username used to connect to the existing database. |
| addons.gitlab.objectStorage.type | string | `""` | Type of object storage to use for Gitlab, setting to s3 will assume an external, pre-existing object storage is to be used. Entering connection info will enable this option and will auto-create any required secrets |
| addons.gitlab.objectStorage.endpoint | string | `""` | S3 compatible endpoint to use for connection information. examples: "https://s3.amazonaws.com" "https://s3.us-gov-west-1.amazonaws.com" "http://minio.minio.svc.cluster.local:9000" |
| addons.gitlab.objectStorage.region | string | `""` | S3 compatible region to use for connection information. |
| addons.gitlab.objectStorage.accessKey | string | `""` | Access key for connecting to object storage endpoint. |
| addons.gitlab.objectStorage.accessSecret | string | `""` | Secret key for connecting to object storage endpoint. Unencoded string data. This should be placed in the secret values and then encrypted |
| addons.gitlab.objectStorage.bucketPrefix | string | `""` | Bucket prefix to use for identifying buckets. Example: "prod" will produce "prod-gitlab-bucket" |
| addons.gitlab.values | object | `{}` | Values to passthrough to the gitlab chart: https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab.git |
| addons.gitlabRunner.enabled | bool | `false` | Toggle deployment of Gitlab Runner. |
| addons.gitlabRunner.git.repo | string | `"https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab-runner.git"` |  |
| addons.gitlabRunner.git.path | string | `"./chart"` |  |
| addons.gitlabRunner.git.tag | string | `"0.19.2-bb.3"` |  |
| addons.gitlabRunner.values | object | `{}` | Values to passthrough to the gitlab runner chart: https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab-runner.git |
| addons.sonarqube.enabled | bool | `false` | Toggle deployment of SonarQube. |
| addons.sonarqube.git.repo | string | `"https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/sonarqube.git"` |  |
| addons.sonarqube.git.path | string | `"./chart"` |  |
| addons.sonarqube.git.tag | string | `"9.2.6-bb.2"` |  |
| addons.sonarqube.sso.enabled | bool | `false` | Toggle OIDC SSO for SonarQube. Enabling this option will auto-create any required secrets. |
| addons.sonarqube.sso.client_id | string | `""` | SonarQube OIDC client ID |
| addons.sonarqube.sso.label | string | `""` | SonarQube SSO login button label |
| addons.sonarqube.sso.certificate | string | `""` | SonarQube plaintext SAML sso certificate. example: MITCAYCBFyIEUjNBkqhkiG9w0BA.... |
| addons.sonarqube.sso.login | string | `"login"` | SonarQube login sso attribute. |
| addons.sonarqube.sso.name | string | `"name"` | SonarQube name sso attribute. |
| addons.sonarqube.sso.email | string | `"email"` | SonarQube email sso attribute. |
| addons.sonarqube.sso.group | string | `"group"` | (optional) SonarQube group sso attribute. |
| addons.sonarqube.database.host | string | `""` | Hostname of a pre-existing PostgreSQL database to use for SonarQube. |
| addons.sonarqube.database.port | int | `5432` | Port of a pre-existing PostgreSQL database to use for SonarQube. |
| addons.sonarqube.database.database | string | `""` | Database name to connect to on host. |
| addons.sonarqube.database.username | string | `""` | Username to connect as to external database, the user must have all privileges on the database. |
| addons.sonarqube.database.password | string | `""` | Database password for the username used to connect to the existing database. |
| addons.sonarqube.values | object | `{}` | Values to passthrough to the sonarqube chart: https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/sonarqube.git |
| addons.haproxy.enabled | bool | `false` | Toggle deployment of HAProxy. |
| addons.haproxy.git.repo | string | `"https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/haproxy"` |  |
| addons.haproxy.git.path | string | `"./chart"` |  |
| addons.haproxy.git.tag | string | `"1.1.2-bb.0"` |  |
| addons.haproxy.values | object | `{}` | Values to passthrough to the haproxy chart: https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/haproxy.git |
| addons.anchore.enabled | bool | `false` | Toggle deployment of Anchore. |
| addons.anchore.git.repo | string | `"https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/anchore-enterprise.git"` |  |
| addons.anchore.git.path | string | `"./chart"` |  |
| addons.anchore.git.tag | string | `"1.9.5-bb.2"` |  |
| addons.anchore.adminPassword | string | `""` | Initial admin password used to authenticate to Anchore. |
| addons.anchore.enterprise | object | `{"enabled":false,"licenseYaml":"FULL LICENSE\n"}` | Anchore Enterprise functionality. |
| addons.anchore.enterprise.enabled | bool | `false` | Toggle the installation of Anchore Enterprise.  This must be accompanied by a valid license. |
| addons.anchore.enterprise.licenseYaml | string | `"FULL LICENSE\n"` | License for Anchore Enterprise. For formatting examples see https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/anchore-enterprise/-/blob/main/docs/CHART.md#enabling-enterprise-services |
| addons.anchore.sso.enabled | bool | `false` | Toggle OIDC SSO for Anchore on and off. Enabling this option will auto-create any required secrets. |
| addons.anchore.sso.client_id | string | `""` | Anchore OIDC client ID |
| addons.anchore.sso.role_attribute | string | `""` | Anchore OIDC client role attribute |
| addons.anchore.database.host | string | `""` | Hostname of a pre-existing PostgreSQL database to use for Anchore. Entering connection info will disable the deployment of an internal database and will auto-create any required secrets. |
| addons.anchore.database.port | string | `""` | Port of a pre-existing PostgreSQL database to use for Anchore. |
| addons.anchore.database.username | string | `""` | Username to connect as to external database, the user must have all privileges on the database. |
| addons.anchore.database.password | string | `""` | Database password for the username used to connect to the existing database. |
| addons.anchore.database.database | string | `""` | Database name to connect to on host. |
| addons.anchore.database.feeds_database | string | `""` | Feeds database name to connect to on host. Only required for enterprise edition of anchore. |
| addons.anchore.redis.host | string | `""` | Hostname of a pre-existing Redis to use for Anchore Enterprise. Entering connection info will enable external redis and will auto-create any required secrets. Anchore only requires redis for enterprise deployments and will not provision an instance if using external |
| addons.anchore.redis.port | string | `""` | Port of a pre-existing Redis to use for Anchore Enterprise. |
| addons.anchore.redis.password | string | `""` | Password to connect to pre-existing Redis. |
| addons.anchore.values | object | `{}` | Values to passthrough to the anchore chart: https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/anchore-enterprise.git |

## Contributing

Please see the [contributing guide](./CONTRIBUTING.md) if you are interested in contributing to Big Bang.
