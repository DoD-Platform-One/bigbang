# bigbang

![Version: 3.3.1](https://img.shields.io/badge/Version-3.3.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

Big Bang is a declarative, continuous delivery tool for core DoD hardened and approved packages into a Kubernetes cluster.

## Getting Started

To start using Big Bang, you will need to create your own Big Bang environment tailored to your needs.  The [Big Bang customer template](https://repo1.dso.mil/big-bang/customers/template) is provided for you to copy into your own Git repository and begin modifications.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Michael Martin | michael.martin.198.ctr@us.af.mil |  |
| Chris O'Connell | christopher.oconnell.2.ctr@us.af.mil |  |
| Andrew Shoell | andrew.shoell.ctr@us.af.mil |  |
| Daniel Pritchett | daniel.pritchett.ctr@spaceforce.mil |  |

## Source Code

* <https://repo1.dso.mil/big-bang/bigbang>

## Requirements

Kubernetes: `>=1.30.0-0`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| domain | string | `"dev.bigbang.mil"` | Domain used for BigBang created exposed services, can be overridden by individual packages. |
| offline | bool | `false` | (experimental) Toggle sourcing from external repos. All this does right now is toggle GitRepositories, it is _not_ fully functional |
| helmRepositories | list | `[]` | List of Helm repositories/credentials to pull helm charts from. OCI Type: Must specify username/password or existingSecret if repository requires auth. Using "private-registry" for existingSecret will reuse credentials from registryCredentials above. Default Type: Must specify existingSecret with auth - see https://fluxcd.io/flux/components/source/helmrepositories/#secret-reference for details on secret data required. |
| registryCredentials | object | `{"email":"","password":"","registry":"registry1.dso.mil","username":""}` | Single set of registry credentials used to pull all images deployed by BigBang. |
| openshift | bool | `false` | Multiple sets of registry credentials used to pull all images deployed by BigBang. Credentials will only be created when a valid combination exists, registry, username, and password (email is optional) Or a list of registires:  - registry: registry1.dso.mil    username: ""    password: ""    email: ""  - registry: registry.dso.mil    username: ""    password: ""    email: "" Openshift Container Platform Feature Toggle |
| git | object | `{"credentials":{"caFile":"","knownHosts":"","password":"","privateKey":"","publicKey":"","username":""},"existingSecret":""}` | Git credential settings for accessing private repositories Order of precedence is:   1. existingSecret   2. http credentials (username/password/caFile)   3. ssh credentials (privateKey/publicKey/knownHosts) |
| git.existingSecret | string | `""` | Existing secret to use for git credentials, must be in the appropriate format: https://toolkit.fluxcd.io/components/source/gitrepositories/#https-authentication |
| git.credentials | object | `{"caFile":"","knownHosts":"","password":"","privateKey":"","publicKey":"","username":""}` | Chart created secrets with user defined values |
| git.credentials.username | string | `""` | HTTP git credentials, both username and password must be provided |
| git.credentials.caFile | string | `""` | HTTPS certificate authority file.  Required for any repo with a self signed certificate |
| git.credentials.privateKey | string | `""` | SSH git credentials, privateKey, publicKey, and knownHosts must be provided |
| sso | object | `{"certificateAuthority":{"cert":"","secretName":"tls-ca-sso"},"name":"SSO","oidc":{"authorization":"{{ .Values.sso.url }}/protocol/openid-connect/auth","claims":{"email":"email","groups":"groups","name":"name","username":"preferred_username"},"endSession":"{{ .Values.sso.url }}/protocol/openid-connect/logout","jwks":"","jwksUri":"{{ .Values.sso.url }}/protocol/openid-connect/certs","token":"{{ .Values.sso.url }}/protocol/openid-connect/token","userinfo":"{{ .Values.sso.url }}/protocol/openid-connect/userinfo"},"saml":{"entityDescriptor":"{{ .Values.sso.url }}/protocol/saml/descriptor","metadata":"","service":"{{ .Values.sso.url }}/protocol/saml"},"url":"https://login.dso.mil/auth/realms/baby-yoda"}` | Global SSO values used for BigBang deployments when sso is enabled |
| sso.name | string | `"SSO"` | Name of the identity provider.  This is used by some packages as the SSO login label. |
| sso.url | string | `"https://login.dso.mil/auth/realms/baby-yoda"` | Base URL for the identity provider. For OIDC, this is the issuer.  For SAML this is the entityID. |
| sso.certificateAuthority | object | `{"cert":"","secretName":"tls-ca-sso"}` | Certificate authority for the identity provider's certificates |
| sso.certificateAuthority.cert | string | `""` | The certificate authority public certificate in .pem format.  Populating this will create a secret in each namespace that enables SSO. |
| sso.certificateAuthority.secretName | string | `"tls-ca-sso"` | The secret name to use for the certificate authority.  Can be manually populated if cert is blank. |
| sso.saml.entityDescriptor | string | `"{{ .Values.sso.url }}/protocol/saml/descriptor"` | SAML entityDescriptor (metadata) path |
| sso.saml.service | string | `"{{ .Values.sso.url }}/protocol/saml"` | SAML SSO Service path |
| sso.saml.metadata | string | `""` | Literal SAML XML metadata retrieved from `{{ .Values.sso.saml.entityDescriptor }}`.  Required for SSO in Nexus, Twistlock, or Sonarqube. |
| sso.oidc | object | `{"authorization":"{{ .Values.sso.url }}/protocol/openid-connect/auth","claims":{"email":"email","groups":"groups","name":"name","username":"preferred_username"},"endSession":"{{ .Values.sso.url }}/protocol/openid-connect/logout","jwks":"","jwksUri":"{{ .Values.sso.url }}/protocol/openid-connect/certs","token":"{{ .Values.sso.url }}/protocol/openid-connect/token","userinfo":"{{ .Values.sso.url }}/protocol/openid-connect/userinfo"}` | OIDC endpoints can be retrieved from `{{ .Values.sso.url }}/.well-known/openid-configuration` |
| sso.oidc.authorization | string | `"{{ .Values.sso.url }}/protocol/openid-connect/auth"` | OIDC authorization path |
| sso.oidc.endSession | string | `"{{ .Values.sso.url }}/protocol/openid-connect/logout"` | OIDC logout / end session path |
| sso.oidc.jwksUri | string | `"{{ .Values.sso.url }}/protocol/openid-connect/certs"` | OIDC JSON Web Key Set (JWKS) path |
| sso.oidc.token | string | `"{{ .Values.sso.url }}/protocol/openid-connect/token"` | OIDC token path |
| sso.oidc.userinfo | string | `"{{ .Values.sso.url }}/protocol/openid-connect/userinfo"` | OIDC user information path |
| sso.oidc.jwks | string | `""` | Literal OIDC JWKS data retrieved from JWKS Uri.  Only needed if `jwsksUri` is not defined. |
| sso.oidc.claims | object | `{"email":"email","groups":"groups","name":"name","username":"preferred_username"}` | Identity provider claim names that store metadata about the authenticated user. |
| sso.oidc.claims.email | string | `"email"` | IdP's claim name used for the user's email address. |
| sso.oidc.claims.name | string | `"name"` | IdP's claim name used for the user's full name |
| sso.oidc.claims.username | string | `"preferred_username"` | IdP's claim name used for the username |
| sso.oidc.claims.groups | string | `"groups"` | IdP's claim name used for the user's groups or roles |
| flux | object | `{"driftDetection":{"ignore":[{"paths":[""],"target":{"kind":"Job"}},{"paths":[""],"target":{"kind":"StatefulSet"}}],"mode":"enabled"},"install":{"remediation":{"retries":-1}},"interval":"2m","rollback":{"cleanupOnFail":true,"timeout":"10m"},"test":{"enable":false},"timeout":"10m","upgrade":{"cleanupOnFail":true,"remediation":{"remediateLastFailure":true,"retries":3}}}` | (Advanced) Flux reconciliation parameters. The default values provided will be sufficient for the majority of workloads. |
| networkPolicies | object | `{"controlPlaneCidr":"0.0.0.0/0","enabled":true,"nodeCidr":"","vpcCidr":"0.0.0.0/0"}` | Global NetworkPolicies settings |
| networkPolicies.enabled | bool | `true` | Toggle all package NetworkPolicies, can disable specific packages with `package.values.networkPolicies.enabled` |
| networkPolicies.controlPlaneCidr | string | `"0.0.0.0/0"` | Control Plane CIDR, defaults to 0.0.0.0/0, use `kubectl get endpoints -n default kubernetes` to get the CIDR range needed for your cluster Must be an IP CIDR range (x.x.x.x/x - ideally with /32 for the specific IP of a single endpoint, broader range for multiple masters/endpoints) Used by package NetworkPolicies to allow Kube API access |
| networkPolicies.nodeCidr | string | `""` | Node CIDR, defaults to allowing "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16" "100.64.0.0/10" networks. use `kubectl get nodes -owide` and review the `INTERNAL-IP` column to derive CIDR range. Must be an IP CIDR range (x.x.x.x/x - ideally a /16 or /24 to include multiple IPs) |
| networkPolicies.vpcCidr | string | `"0.0.0.0/0"` | VPC CIDR, defaults to 0.0.0.0/0 In a production environment, it is recommended to setup a Private Endpoint for your AWS services like KMS or S3. Please review https://docs.aws.amazon.com/kms/latest/developerguide/kms-vpc-endpoint.html to setup routing to AWS services that never leave the AWS network. Once created update `networkPolicies.vpcCidr` to match the CIDR of your VPC so Vault will be able to reach your VPCs DNS and new KMS endpoint. |
| imagePullPolicy | string | `"IfNotPresent"` | Global ImagePullPolicy value for all packages Permitted values are: None, Always, IfNotPresent |
| disableAutomaticPassthroughValues | bool | `false` | Flag for temporary workaround for passthrough chart migrations This is the global flag to disable automatic passthrough values for all packages. Alternatively, you can set this flag to `true` in the individual package values to disable passthrough for that package. This will be removed in a future release. |
| istioCRDs.enabled | bool | `true` | Toggle deployment of Istio CRDs |
| istioCRDs.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| istioCRDs.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/istio-crds.git"` |  |
| istioCRDs.git.path | string | `"./chart"` |  |
| istioCRDs.git.tag | string | `"1.26.2-bb.0"` |  |
| istioCRDs.helmRepo.repoName | string | `"registry1"` |  |
| istioCRDs.helmRepo.chartName | string | `"istio-crds"` |  |
| istioCRDs.helmRepo.tag | string | `"1.26.2-bb.0"` |  |
| istioCRDs.values | object | `{}` | Values to passthrough to the Istio CRDs chart |
| istioCRDs.flux | object | `{"driftDetection":{"ignore":[{"paths":["/webhooks/0/failurePolicy"],"target":{"kind":"ValidatingWebhookConfiguration","name":"istiod-default-validator"}},{"paths":[""],"target":{"kind":"Job"}},{"paths":[""],"target":{"kind":"StatefulSet"}}],"mode":"warn"}}` | Flux reconciliation overrides specifically for the Istio CRDs Package |
| istioCRDs.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| istiod.enabled | bool | `true` | Toggle deployment of istiod |
| istiod.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| istiod.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/istiod.git"` |  |
| istiod.git.path | string | `"./chart"` |  |
| istiod.git.tag | string | `"1.26.2-bb.0"` |  |
| istiod.helmRepo.repoName | string | `"registry1"` |  |
| istiod.helmRepo.chartName | string | `"istiod"` |  |
| istiod.helmRepo.tag | string | `"1.26.2-bb.0"` |  |
| istiod.values | object | `{}` | Values to passthrough to the istiod chart |
| istiod.flux | object | `{"driftDetection":{"ignore":[{"paths":["/webhooks/0/failurePolicy"],"target":{"kind":"ValidatingWebhookConfiguration","name":"istio-validator-istio-system"}},{"paths":[""],"target":{"kind":"Job"}},{"paths":[""],"target":{"kind":"StatefulSet"}}],"mode":"warn"}}` | Flux reconciliation overrides specifically for the Istio Core Package |
| istiod.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| istioGateway.enabled | bool | `true` | Toggle deployment of Istio Gateway(s) |
| istioGateway.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| istioGateway.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/istio-gateway.git"` |  |
| istioGateway.git.path | string | `"./chart"` |  |
| istioGateway.git.tag | string | `"1.26.2-bb.0"` |  |
| istioGateway.helmRepo.repoName | string | `"registry1"` |  |
| istioGateway.helmRepo.chartName | string | `"gateway"` |  |
| istioGateway.helmRepo.tag | string | `"1.26.2-bb.0"` |  |
| istioGateway.values | object | `{}` | Values to passthrough to the gateway chart(s) |
| istioGateway.flux | object | `{"driftDetection":{"ignore":[{"paths":[""],"target":{"kind":"PeerAuthentication","namespace":"istio-gateway"}},{"paths":[""],"target":{"kind":"AuthorizationPolicy","namespace":"istio-gateway"}},{"paths":[""],"target":{"kind":"NetworkPolicy","namespace":"istio-gateway"}}]}}` | Flux reconciliation overrides specifically for the Istio Gateway Package |
| istioGateway.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md The istioGateway package supports advanced postRenderer definitions. If an array of postRenderers is provided, the postRenderers will be applied to all gateways. If a map of postRenderers is provided, the postRenderers will be applied only to their respective gateways. The map key must match the gateway name for the postRenderers to be applied to that gateway. You cannot mix array and map postRenderers. |
| kiali.enabled | bool | `true` | Toggle deployment of Kiali. |
| kiali.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| kiali.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/kiali.git"` |  |
| kiali.git.path | string | `"./chart"` |  |
| kiali.git.tag | string | `"2.10.0-bb.3"` |  |
| kiali.helmRepo.repoName | string | `"registry1"` |  |
| kiali.helmRepo.chartName | string | `"kiali"` |  |
| kiali.helmRepo.tag | string | `"2.10.0-bb.3"` |  |
| kiali.flux | object | `{"driftDetection":{"ignore":[{"paths":[""],"target":{"kind":"Kiali"}}]}}` | Flux reconciliation overrides specifically for the Kiali Package |
| kiali.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| kiali.sso.enabled | bool | `false` | Toggle SSO for Kiali on and off |
| kiali.sso.client_id | string | `""` | OIDC Client ID to use for Kiali |
| kiali.sso.client_secret | string | `""` | OIDC Client Secret to use for Kiali |
| kiali.values | object | `{}` | Values to pass through to Kiali chart: https://repo1.dso.mil/big-bang/product/packages/kiali |
| kiali.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| gatekeeper.enabled | bool | `false` | Toggle deployment of OPA Gatekeeper. |
| gatekeeper.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| gatekeeper.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/policy.git"` |  |
| gatekeeper.git.path | string | `"./chart"` |  |
| gatekeeper.git.tag | string | `"3.19.1-bb.0"` |  |
| gatekeeper.helmRepo.repoName | string | `"registry1"` |  |
| gatekeeper.helmRepo.chartName | string | `"gatekeeper"` |  |
| gatekeeper.helmRepo.tag | string | `"3.19.1-bb.0"` |  |
| gatekeeper.flux | object | `{"install":{"crds":"CreateReplace"},"upgrade":{"crds":"CreateReplace"}}` | Flux reconciliation overrides specifically for the OPA Gatekeeper Package |
| gatekeeper.values | object | `{}` | Values to passthrough to the gatekeeper chart: https://repo1.dso.mil/big-bang/product/packages/policy.git |
| gatekeeper.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| kyverno.enabled | bool | `true` | Toggle deployment of Kyverno. |
| kyverno.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| kyverno.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/kyverno.git"` |  |
| kyverno.git.path | string | `"./chart"` |  |
| kyverno.git.tag | string | `"3.4.4-bb.0"` |  |
| kyverno.helmRepo.repoName | string | `"registry1"` |  |
| kyverno.helmRepo.chartName | string | `"kyverno"` |  |
| kyverno.helmRepo.tag | string | `"3.4.4-bb.0"` |  |
| kyverno.flux | object | `{"driftDetection":{"ignore":[{"paths":[""],"target":{"kind":"CustomResourceDefinition"}},{"paths":[""],"target":{"kind":"Job"}},{"paths":[""],"target":{"kind":"StatefulSet"}}]},"install":{"crds":"CreateReplace"},"upgrade":{"crds":"CreateReplace"}}` | Flux reconciliation overrides specifically for the Kyverno Package |
| kyverno.values | object | `{}` | Values to passthrough to the kyverno chart: https://repo1.dso.mil/big-bang/product/packages/kyverno.git |
| kyverno.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| kyvernoPolicies.enabled | bool | `true` | Toggle deployment of Kyverno policies |
| kyvernoPolicies.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| kyvernoPolicies.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/kyverno-policies.git"` |  |
| kyvernoPolicies.git.path | string | `"./chart"` |  |
| kyvernoPolicies.git.tag | string | `"3.3.4-bb.10"` |  |
| kyvernoPolicies.helmRepo.repoName | string | `"registry1"` |  |
| kyvernoPolicies.helmRepo.chartName | string | `"kyverno-policies"` |  |
| kyvernoPolicies.helmRepo.tag | string | `"3.3.4-bb.10"` |  |
| kyvernoPolicies.flux | object | `{"driftDetection":{"ignore":[{"paths":[""],"target":{"kind":"ClusterPolicy"}},{"paths":[""],"target":{"kind":"Job"}},{"paths":[""],"target":{"kind":"StatefulSet"}}]}}` | Flux reconciliation overrides specifically for the Kyverno Package |
| kyvernoPolicies.values | object | `{}` | Values to passthrough to the kyverno policies chart: https://repo1.dso.mil/big-bang/product/packages/kyverno-policies.git |
| kyvernoPolicies.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| kyvernoReporter.enabled | bool | `true` | Toggle deployment of Kyverno Reporter |
| kyvernoReporter.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| kyvernoReporter.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/kyverno-reporter.git"` |  |
| kyvernoReporter.git.path | string | `"./chart"` |  |
| kyvernoReporter.git.tag | string | `"3.1.4-bb.0"` |  |
| kyvernoReporter.helmRepo.repoName | string | `"registry1"` |  |
| kyvernoReporter.helmRepo.chartName | string | `"kyverno-reporter"` |  |
| kyvernoReporter.helmRepo.tag | string | `"3.1.4-bb.0"` |  |
| kyvernoReporter.flux | object | `{}` | Flux reconciliation overrides specifically for the Kyverno Reporter Package |
| kyvernoReporter.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| kyvernoReporter.values | object | `{}` | Values to passthrough to the kyverno reporter chart: https://repo1.dso.mil/big-bang/product/packages/kyverno-reporter.git |
| kyvernoReporter.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| elasticsearchKibana.enabled | bool | `false` | Toggle deployment of Logging (EFK). |
| elasticsearchKibana.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| elasticsearchKibana.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/elasticsearch-kibana.git"` |  |
| elasticsearchKibana.git.path | string | `"./chart"` |  |
| elasticsearchKibana.git.tag | string | `"1.30.0-bb.2"` |  |
| elasticsearchKibana.helmRepo.repoName | string | `"registry1"` |  |
| elasticsearchKibana.helmRepo.chartName | string | `"elasticsearch-kibana"` |  |
| elasticsearchKibana.helmRepo.tag | string | `"1.30.0-bb.2"` |  |
| elasticsearchKibana.flux | object | `{"driftDetection":{"ignore":[{"paths":[""],"target":{"kind":"Kibana"}},{"paths":[""],"target":{"kind":"Elasticsearch"}},{"paths":[""],"target":{"kind":"Job"}},{"paths":[""],"target":{"kind":"StatefulSet"}}]},"timeout":"20m"}` | Flux reconciliation overrides specifically for the Logging (EFK) Package |
| elasticsearchKibana.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| elasticsearchKibana.sso.enabled | bool | `false` | Toggle OIDC SSO for Kibana/Elasticsearch on and off. Enabling this option will auto-create any required secrets. |
| elasticsearchKibana.sso.client_id | string | `""` | Elasticsearch/Kibana OIDC client ID |
| elasticsearchKibana.sso.client_secret | string | `""` | Elasticsearch/Kibana OIDC client secret |
| elasticsearchKibana.serviceAccountAnnotations | object | `{"elasticsearch":{},"kibana":{}}` | Elasticsearch/Kibana Service Account Annotations |
| elasticsearchKibana.license.trial | bool | `false` | Toggle trial license installation of elasticsearch.  Note that enterprise (non trial) is required for SSO to work. |
| elasticsearchKibana.license.keyJSON | string | `""` | Elasticsearch license in json format seen here: https://repo1.dso.mil/big-bang/product/packages/elasticsearch-kibana#enterprise-license |
| elasticsearchKibana.values | object | `{}` | Values to passthrough to the elasticsearch-kibana chart: https://repo1.dso.mil/big-bang/product/packages/elasticsearch-kibana.git |
| elasticsearchKibana.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| eckOperator.enabled | bool | `false` | Toggle deployment of ECK Operator. |
| eckOperator.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| eckOperator.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/eck-operator.git"` |  |
| eckOperator.git.path | string | `"./chart"` |  |
| eckOperator.git.tag | string | `"3.0.0-bb.2"` |  |
| eckOperator.helmRepo.repoName | string | `"registry1"` |  |
| eckOperator.helmRepo.chartName | string | `"eck-operator"` |  |
| eckOperator.helmRepo.tag | string | `"3.0.0-bb.2"` |  |
| eckOperator.flux | object | `{}` | Flux reconciliation overrides specifically for the ECK Operator Package |
| eckOperator.values | object | `{}` | Values to passthrough to the eck-operator chart: https://repo1.dso.mil/big-bang/product/packages/eck-operator.git |
| eckOperator.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| fluentbit.enabled | bool | `false` | Toggle deployment of Fluent-Bit. |
| fluentbit.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| fluentbit.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/fluentbit.git"` |  |
| fluentbit.git.path | string | `"./chart"` |  |
| fluentbit.git.tag | string | `"0.49.1-bb.0"` |  |
| fluentbit.helmRepo.repoName | string | `"registry1"` |  |
| fluentbit.helmRepo.chartName | string | `"fluentbit"` |  |
| fluentbit.helmRepo.tag | string | `"0.49.1-bb.0"` |  |
| fluentbit.flux | object | `{}` | Flux reconciliation overrides specifically for the Fluent-Bit Package |
| fluentbit.values | object | `{}` | Values to passthrough to the fluentbit chart: https://repo1.dso.mil/big-bang/product/packages/fluentbit.git |
| fluentbit.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| promtail.enabled | bool | `false` | Toggle deployment of Promtail. |
| promtail.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| promtail.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/promtail.git"` |  |
| promtail.git.path | string | `"./chart"` |  |
| promtail.git.tag | string | `"6.16.6-bb.5"` |  |
| promtail.helmRepo.repoName | string | `"registry1"` |  |
| promtail.helmRepo.chartName | string | `"promtail"` |  |
| promtail.helmRepo.tag | string | `"6.16.6-bb.5"` |  |
| promtail.flux | object | `{}` | Flux reconciliation overrides specifically for the Promtail Package |
| promtail.values | object | `{}` | Values to passthrough to the promtail chart: https://repo1.dso.mil/big-bang/product/packages/fluentbit.git |
| promtail.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| loki.enabled | bool | `true` | Toggle deployment of Loki. |
| loki.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| loki.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/loki.git"` |  |
| loki.git.path | string | `"./chart"` |  |
| loki.git.tag | string | `"6.30.1-bb.3"` |  |
| loki.helmRepo.repoName | string | `"registry1"` |  |
| loki.helmRepo.chartName | string | `"loki"` |  |
| loki.helmRepo.tag | string | `"6.30.1-bb.3"` |  |
| loki.flux | object | `{"driftDetection":{"ignore":[{"paths":[""],"target":{"kind":"Tenant"}},{"paths":[""],"target":{"kind":"Sidecar"}},{"paths":[""],"target":{"kind":"Job"}},{"paths":[""],"target":{"kind":"StatefulSet"}}]}}` | Flux reconciliation overrides specifically for the Loki Package |
| loki.strategy | string | `"monolith"` | Loki architecture.  Options are monolith and scalable |
| loki.clusterName | string | `""` | Loki clusterName identifier for Promtail and Dashboards |
| loki.objectStorage.endpoint | string | `""` | S3 compatible endpoint to use for connection information. examples: "https://s3.amazonaws.com" "https://s3.us-gov-west-1.amazonaws.com" "http://minio.minio.svc.cluster.local:9000" |
| loki.objectStorage.region | string | `""` | S3 compatible region to use for connection information. |
| loki.objectStorage.accessKey | string | `""` | Access key for connecting to object storage endpoint. |
| loki.objectStorage.accessSecret | string | `""` | Secret key for connecting to object storage endpoint. Unencoded string data. This should be placed in the secret values and then encrypted |
| loki.objectStorage.bucketNames | object | `{}` | Bucket Names for the Loki buckets as YAML chunks: loki-logs ruler: loki-ruler admin: loki-admin |
| loki.values | object | `{}` | Values to passthrough to the Loki chart: https://repo1.dso.mil/big-bang/product/packages/loki.git |
| loki.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| neuvector.enabled | bool | `true` | Toggle deployment of Neuvector. |
| neuvector.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| neuvector.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/neuvector.git"` |  |
| neuvector.git.path | string | `"./chart"` |  |
| neuvector.git.tag | string | `"2.8.6-bb.0"` |  |
| neuvector.helmRepo.repoName | string | `"registry1"` |  |
| neuvector.helmRepo.chartName | string | `"neuvector"` |  |
| neuvector.helmRepo.tag | string | `"2.8.6-bb.0"` |  |
| neuvector.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| neuvector.sso.enabled | bool | `false` | Toggle SSO for Neuvector on and off |
| neuvector.sso.client_id | string | `""` | OIDC Client ID to use for Neuvector |
| neuvector.sso.client_secret | string | `""` | OIDC Client Secret to use for Neuvector |
| neuvector.sso.default_role | string | `""` | Default role to use for Neuvector OIDC users. Supports admin, reader, or no default |
| neuvector.sso.group_claim | string | `""` | Default role to use for Neuvector OIDC users. Supports admin, reader, or no default |
| neuvector.sso.group_mapped_roles | list | `[]` | Default role to use for Neuvector OIDC users. Supports admin, reader, or no default |
| neuvector.flux | object | `{"driftDetection":{"ignore":[{"paths":[""],"target":{"kind":"CronJob"}},{"paths":[""],"target":{"kind":"Lease"}},{"paths":[""],"target":{"kind":"Secret"}},{"paths":[""],"target":{"kind":"Job"}},{"paths":[""],"target":{"kind":"StatefulSet"}}]}}` | Flux reconciliation overrides specifically for the Neuvector Package |
| neuvector.values | object | `{}` | Values to passthrough to the Neuvector chart: https://repo1.dso.mil/big-bang/product/packages/neuvector.git |
| neuvector.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| tempo.enabled | bool | `true` | Toggle deployment of Tempo. |
| tempo.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| tempo.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/tempo.git"` |  |
| tempo.git.path | string | `"./chart"` |  |
| tempo.git.tag | string | `"1.21.1-bb.2"` |  |
| tempo.helmRepo.repoName | string | `"registry1"` |  |
| tempo.helmRepo.chartName | string | `"tempo"` |  |
| tempo.helmRepo.tag | string | `"1.21.1-bb.2"` |  |
| tempo.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| tempo.flux | object | `{}` | Flux reconciliation overrides specifically for the Tempo Package |
| tempo.sso.enabled | bool | `false` | Toggle SSO for Tempo on and off |
| tempo.sso.client_id | string | `""` | OIDC Client ID to use for Tempo |
| tempo.sso.client_secret | string | `""` | OIDC Client Secret to use for Tempo |
| tempo.objectStorage.endpoint | string | `""` | S3 compatible endpoint to use for connection information. examples: "s3.amazonaws.com" "s3.us-gov-west-1.amazonaws.com" "minio.minio.svc.cluster.local:9000" Note: tempo does not require protocol prefix for URL. |
| tempo.objectStorage.region | string | `""` | S3 compatible region to use for connection information. |
| tempo.objectStorage.accessKey | string | `""` | Access key for connecting to object storage endpoint. |
| tempo.objectStorage.accessSecret | string | `""` | Secret key for connecting to object storage endpoint. Unencoded string data. This should be placed in the secret values and then encrypted |
| tempo.objectStorage.bucket | string | `""` | Bucket Name for Tempo examples: "tempo-traces" |
| tempo.objectStorage.insecure | bool | `false` | Whether or not objectStorage connection should require HTTPS, if connecting to in-cluster object storage on port 80/9000 set this value to true. |
| tempo.metricsGenerator | object | `{"enabled":false}` | Whether or not to enable Tempo's internal metrics generator, the monitoring package will also be be required for this integration. |
| tempo.values | object | `{}` | Values to passthrough to the Tempo chart: https://repo1.dso.mil/big-bang/product/packages/tempo.git |
| tempo.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| monitoring.enabled | bool | `true` | Toggle deployment of Monitoring (Prometheus, Grafana, and Alertmanager). |
| monitoring.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| monitoring.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/monitoring.git"` |  |
| monitoring.git.path | string | `"./chart"` |  |
| monitoring.git.tag | string | `"75.6.1-bb.1"` |  |
| monitoring.helmRepo.repoName | string | `"registry1"` |  |
| monitoring.helmRepo.chartName | string | `"monitoring"` |  |
| monitoring.helmRepo.tag | string | `"75.6.1-bb.1"` |  |
| monitoring.flux | object | `{"driftDetection":{"ignore":[{"paths":[""],"target":{"kind":"Alertmanager"}},{"paths":[""],"target":{"kind":"Prometheus"}},{"paths":[""],"target":{"kind":"PrometheusRule"}},{"paths":[""],"target":{"kind":"Job"}},{"paths":[""],"target":{"kind":"StatefulSet"}}]},"install":{"crds":"CreateReplace"},"upgrade":{"crds":"CreateReplace"}}` | Flux reconciliation overrides specifically for the Monitoring Package |
| monitoring.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| monitoring.sso.enabled | bool | `false` | Toggle SSO for monitoring components on and off |
| monitoring.sso.prometheus.client_id | string | `""` | Prometheus OIDC client ID |
| monitoring.sso.prometheus.client_secret | string | `""` | Prometheus OIDC client secret |
| monitoring.sso.alertmanager.client_id | string | `""` | Alertmanager OIDC client ID |
| monitoring.sso.alertmanager.client_secret | string | `""` | Alertmanager OIDC client secret |
| monitoring.values | object | `{}` | Values to passthrough to the monitoring chart: https://repo1.dso.mil/big-bang/product/packages/monitoring.git |
| monitoring.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| grafana.enabled | bool | `true` | Toggle deployment of Grafana |
| grafana.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| grafana.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/grafana.git"` |  |
| grafana.git.path | string | `"./chart"` |  |
| grafana.git.tag | string | `"9.2.10-bb.0"` |  |
| grafana.helmRepo.repoName | string | `"registry1"` |  |
| grafana.helmRepo.chartName | string | `"grafana"` |  |
| grafana.helmRepo.tag | string | `"9.2.10-bb.0"` |  |
| grafana.flux | object | `{}` | Flux reconciliation overrides specifically for the Monitoring Package |
| grafana.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| grafana.sso.enabled | bool | `false` | Toggle SSO for grafana components on and off |
| grafana.sso.grafana.client_id | string | `""` | Grafana OIDC client ID |
| grafana.sso.grafana.client_secret | string | `""` | Grafana OIDC client secret |
| grafana.sso.grafana.scopes | string | `""` | Grafana OIDC client scopes, comma separated, see https://grafana.com/docs/grafana/latest/auth/generic-oauth/ |
| grafana.sso.grafana.allow_sign_up | bool | `true` |  |
| grafana.sso.grafana.role_attribute_path | string | `"Viewer"` |  |
| grafana.values | object | `{}` | Values to passthrough to the grafana chart: https://repo1.dso.mil/big-bang/product/packages/grafana.git |
| grafana.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| twistlock.enabled | bool | `false` | Toggle deployment of Twistlock. |
| twistlock.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| twistlock.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/twistlock.git"` |  |
| twistlock.git.path | string | `"./chart"` |  |
| twistlock.git.tag | string | `"0.21.0-bb.1"` |  |
| twistlock.helmRepo.repoName | string | `"registry1"` |  |
| twistlock.helmRepo.chartName | string | `"twistlock"` |  |
| twistlock.helmRepo.tag | string | `"0.21.0-bb.1"` |  |
| twistlock.flux | object | `{}` | Flux reconciliation overrides specifically for the Twistlock Package |
| twistlock.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| twistlock.sso.enabled | bool | `false` | Toggle SAML SSO, requires a license and enabling the init job - see https://repo1.dso.mil/big-bang/product/packages/initialization.md |
| twistlock.sso.client_id | string | `""` | SAML client ID |
| twistlock.sso.provider_type | string | `"shibboleth"` | SAML Identity Provider. `shibboleth` is recommended by Twistlock support for Keycloak Possible values: okta, gsuite, ping, shibboleth, azure, adfs |
| twistlock.sso.groups | string | `""` | Groups attribute (optional) |
| twistlock.values | object | `{}` | Values to passthrough to the twistlock chart: https://repo1.dso.mil/big-bang/product/packages/twistlock.git |
| twistlock.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| bbctl.enabled | bool | `true` | Toggle deployment of the bbctl dashboards |
| bbctl.sourceType | string | `"git"` |  |
| bbctl.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/bbctl.git"` |  |
| bbctl.git.tag | string | `"2.1.0-bb.1"` |  |
| bbctl.git.path | string | `"./chart"` |  |
| bbctl.helmRepo.repoName | string | `"registry1"` |  |
| bbctl.helmRepo.chartName | string | `"bbctl"` |  |
| bbctl.helmRepo.tag | string | `"2.1.0-bb.1"` |  |
| bbctl.repoCredentials.repo | string | `"repo1.dso.mil"` |  |
| bbctl.repoCredentials.username | string | `""` |  |
| bbctl.repoCredentials.password | string | `""` |  |
| bbctl.flux | object | `{}` | Override flux settings for this package |
| bbctl.values | object | `{}` |  |
| bbctl.postRenderers | list | `[]` |  |
| alloy.enabled | bool | `true` | Toggle deployment of grafana alloy |
| alloy.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| alloy.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/alloy.git"` |  |
| alloy.git.tag | string | `"3.0.2-bb.0"` |  |
| alloy.git.path | string | `"./chart"` |  |
| alloy.helmRepo.repoName | string | `"registry1"` |  |
| alloy.helmRepo.chartName | string | `"k8s-monitoring"` |  |
| alloy.helmRepo.tag | string | `"3.0.2-bb.0"` |  |
| alloy.alloyLogs | object | `{"enabled":true}` | Toggle Alloy to collect logs |
| alloy.additionalDestinations | list | `[]` | Additional Alloy destinations not included in Big Bang |
| alloy.values | object | `{}` |  |
| alloy.postRenderers | list | `[]` |  |
| alloy.flux | object | `{}` | Flux reconciliation overrides specifically for the alloy package |
| addons.argocd.enabled | bool | `false` | Toggle deployment of ArgoCD. |
| addons.argocd.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.argocd.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/argocd.git"` |  |
| addons.argocd.git.path | string | `"./chart"` |  |
| addons.argocd.git.tag | string | `"8.0.10-bb.2"` |  |
| addons.argocd.helmRepo.repoName | string | `"registry1"` |  |
| addons.argocd.helmRepo.chartName | string | `"argocd"` |  |
| addons.argocd.helmRepo.tag | string | `"8.0.10-bb.2"` |  |
| addons.argocd.flux | object | `{}` | Flux reconciliation overrides specifically for the ArgoCD Package |
| addons.argocd.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| addons.argocd.redis.host | string | `""` | Hostname of a pre-existing Redis to use for ArgoCD. Entering connection info will enable external Redis and will auto-create any required secrets. |
| addons.argocd.redis.port | string | `""` | Port of a pre-existing Redis to use for ArgoCD. |
| addons.argocd.sso.enabled | bool | `false` | Toggle SSO for ArgoCD on and off |
| addons.argocd.sso.client_id | string | `""` | ArgoCD OIDC client ID |
| addons.argocd.sso.client_secret | string | `""` | ArgoCD OIDC client secret |
| addons.argocd.sso.groups | string | `"g, Impact Level 2 Authorized, role:admin\n"` | ArgoCD SSO group roles, see docs for more details: https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/ |
| addons.argocd.values | object | `{}` | Values to passthrough to the argocd chart: https://repo1.dso.mil/big-bang/product/packages/argocd.git |
| addons.argocd.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| addons.backstage.enabled | bool | `false` | Toggle deployment of Backstage. |
| addons.backstage.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.backstage.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/backstage.git"` |  |
| addons.backstage.git.path | string | `"./chart"` |  |
| addons.backstage.git.tag | string | `"2.5.3-bb.1"` |  |
| addons.backstage.helmRepo.repoName | string | `"registry1"` |  |
| addons.backstage.helmRepo.chartName | string | `"backstage"` |  |
| addons.backstage.helmRepo.tag | string | `"2.5.3-bb.1"` |  |
| addons.backstage.flux | object | `{}` | Flux reconciliation overrides specifically for the Backstage Package |
| addons.backstage.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| addons.backstage.sso.enabled | bool | `false` | Toggle SSO for Backstage on and off |
| addons.backstage.sso.client_id | string | `""` | Backstage OIDC client ID |
| addons.backstage.sso.client_secret | string | `""` | Backstage OIDC client secret |
| addons.backstage.values | object | `{}` | Values to passthrough to the Backstage chart: https://repo1.dso.mil/big-bang/product/packages/backstage.git |
| addons.backstage.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| addons.authservice.enabled | bool | `false` | Toggle deployment of Authservice. if enabling authservice, a filter needs to be provided by either enabling sso for monitoring or istio, or manually adding a filter chain in the values here: values:   chain:     minimal:       callback_uri: "https://somecallback" |
| addons.authservice.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.authservice.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/authservice.git"` |  |
| addons.authservice.git.path | string | `"./chart"` |  |
| addons.authservice.git.tag | string | `"1.0.4-bb.3"` |  |
| addons.authservice.helmRepo.repoName | string | `"registry1"` |  |
| addons.authservice.helmRepo.chartName | string | `"authservice"` |  |
| addons.authservice.helmRepo.tag | string | `"1.0.4-bb.3"` |  |
| addons.authservice.flux | object | `{}` | Flux reconciliation overrides specifically for the Authservice Package |
| addons.authservice.values | object | `{}` | Values to passthrough to the authservice chart: https://repo1.dso.mil/big-bang/product/packages/authservice.git |
| addons.authservice.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| addons.authservice.chains | object | `{}` | Additional authservice chain configurations. |
| addons.minioOperator.enabled | bool | `false` | Toggle deployment of minio operator and instance. |
| addons.minioOperator.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.minioOperator.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/minio-operator.git"` |  |
| addons.minioOperator.git.path | string | `"./chart"` |  |
| addons.minioOperator.git.tag | string | `"7.1.1-bb.0"` |  |
| addons.minioOperator.helmRepo.repoName | string | `"registry1"` |  |
| addons.minioOperator.helmRepo.chartName | string | `"minio-operator"` |  |
| addons.minioOperator.helmRepo.tag | string | `"7.1.1-bb.0"` |  |
| addons.minioOperator.flux | object | `{}` | Flux reconciliation overrides specifically for the Minio Operator Package |
| addons.minioOperator.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| addons.minioOperator.values | object | `{}` | Values to passthrough to the minio operator chart: https://repo1.dso.mil/big-bang/product/packages/minio-operator.git |
| addons.minioOperator.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| addons.minio.enabled | bool | `false` | Toggle deployment of minio. |
| addons.minio.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.minio.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/minio.git"` |  |
| addons.minio.git.path | string | `"./chart"` |  |
| addons.minio.git.tag | string | `"7.1.1-bb.5"` |  |
| addons.minio.helmRepo.repoName | string | `"registry1"` |  |
| addons.minio.helmRepo.chartName | string | `"minio-instance"` |  |
| addons.minio.helmRepo.tag | string | `"7.1.1-bb.5"` |  |
| addons.minio.flux | object | `{}` | Flux reconciliation overrides specifically for the Minio Package |
| addons.minio.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| addons.minio.accesskey | string | `""` | Default access key to use for minio. |
| addons.minio.secretkey | string | `""` | Default secret key to intstantiate with minio, you should change/delete this after installation. |
| addons.minio.values | object | `{}` | Values to passthrough to the minio instance chart: https://repo1.dso.mil/big-bang/product/packages/minio.git |
| addons.minio.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| addons.gitlab.enabled | bool | `false` | Toggle deployment of Gitlab |
| addons.gitlab.hostnames.gitlab | string | `"gitlab"` |  |
| addons.gitlab.hostnames.registry | string | `"registry"` |  |
| addons.gitlab.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.gitlab.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/gitlab.git"` |  |
| addons.gitlab.git.path | string | `"./chart"` |  |
| addons.gitlab.git.tag | string | `"9.2.1-bb.0"` |  |
| addons.gitlab.helmRepo.repoName | string | `"registry1"` |  |
| addons.gitlab.helmRepo.chartName | string | `"gitlab"` |  |
| addons.gitlab.helmRepo.tag | string | `"9.2.1-bb.0"` |  |
| addons.gitlab.flux | object | `{}` | Flux reconciliation overrides specifically for the Gitlab Package |
| addons.gitlab.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| addons.gitlab.sso.enabled | bool | `false` | Toggle OIDC SSO for Gitlab on and off. Enabling this option will auto-create any required secrets. |
| addons.gitlab.sso.client_id | string | `""` | Gitlab OIDC client ID |
| addons.gitlab.sso.client_secret | string | `""` | Gitlab OIDC client secret |
| addons.gitlab.sso.scopes | list | `["Gitlab"]` | Gitlab SSO Scopes, default is ["Gitlab"] |
| addons.gitlab.sso.groups | list | `[]` | Fill out the groups block below and populate with Keycloak groups according to your desired Gitlab membership requirements. The default groupsAttribute is "groups". Full documentation: https://docs.gitlab.com/ee/administration/auth/oidc.html?tab=Linux+package+%28Omnibus%29#configure-users-based-on-oidc-group-membership |
| addons.gitlab.database.host | string | `""` | Hostname of a pre-existing PostgreSQL database to use for Gitlab. Entering connection info will disable the deployment of an internal database and will auto-create any required secrets. |
| addons.gitlab.database.port | int | `5432` | Port of a pre-existing PostgreSQL database to use for Gitlab. |
| addons.gitlab.database.database | string | `""` | Database name to connect to on host. |
| addons.gitlab.database.username | string | `""` | Username to connect as to external database, the user must have all privileges on the database. |
| addons.gitlab.database.password | string | `""` | Database password for the username used to connect to the existing database. |
| addons.gitlab.objectStorage.type | string | `""` | Type of object storage to use for Gitlab, setting to s3 will assume an external, pre-existing object storage is to be used. Entering connection info will enable this option and will auto-create any required secrets |
| addons.gitlab.objectStorage.endpoint | string | `""` | S3 compatible endpoint to use for connection information. examples: "https://s3.amazonaws.com" "https://s3.us-gov-west-1.amazonaws.com" "http://minio.minio.svc.cluster.local:9000" |
| addons.gitlab.objectStorage.regionendpoint | string | `""` | S3 compatible service endpoint for use with Minio or aws S3.  See: https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/examples/objectstorage Setting this allows the registry to use a different endpoint than the global `objectStorage.endpoint` documented above. `objectStorage.endpoint` must be set in order for `objectStorage.regionendpoint` endpoint to be used.  See: https://docs.gitlab.com/administration/object_storage/ Also note rails.s3.yaml and registry.s3.yaml here for implementation parallel: https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/examples/objectstorage examples:  "https://s3.us-gov-west-1.amazonaws.com" "https://minio.example.com:9000" |
| addons.gitlab.objectStorage.region | string | `""` | S3 compatible region to use for connection information. |
| addons.gitlab.objectStorage.accessKey | string | `""` | Access key for connecting to object storage endpoint. -- If using accessKey and accessSecret, the iamProfile must be left as an empty string: "" |
| addons.gitlab.objectStorage.accessSecret | string | `""` | Secret key for connecting to object storage endpoint. Unencoded string data. This should be placed in the secret values and then encrypted |
| addons.gitlab.objectStorage.bucketPrefix | string | `""` | Bucket prefix to use for identifying buckets. Example: "prod" will produce "prod-gitlab-bucket" |
| addons.gitlab.objectStorage.iamProfile | string | `""` | NOTE: Current bug with AWS IAM Profiles and Object Storage where only artifacts are stored. Fixed in Gitlab 14.5 -- Name of AWS IAM profile to use. -- If using an AWS IAM profile, the accessKey and accessSecret values must be left as empty strings eg: "" |
| addons.gitlab.smtp.password | string | `""` | Passwords should be placed in an encrypted file. Example: environment-bb-secret.enc.yaml If a value is provided BigBang will create a k8s secret named gitlab-smtp-password in the gitlab namespace |
| addons.gitlab.redis.password | string | `""` | Redis plain text password to connect to the redis server.  If empty (""), the gitlab charts will create the gitlab-redis-secret with a random password. -- This needs to be set to a non-empty value in order for the Grafana Redis Datasource and Dashboards to be installed. |
| addons.gitlab.railsSecret | string | `""` | Rails plain text secret to define. If empty (""), the gitlab charts will create the gitlab-rails-secret with randomized data. Read the following for more information on setting Gitlab rails secrets: https://docs.gitlab.com/charts/installation/secrets#gitlab-rails-secret |
| addons.gitlab.values | object | `{}` | Values to passthrough to the gitlab chart: https://repo1.dso.mil/big-bang/product/packages/gitlab.git |
| addons.gitlab.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| addons.gitlabRunner.enabled | bool | `false` | Toggle deployment of Gitlab Runner |
| addons.gitlabRunner.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.gitlabRunner.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/gitlab-runner.git"` |  |
| addons.gitlabRunner.git.path | string | `"./chart"` |  |
| addons.gitlabRunner.git.tag | string | `"0.77.2-bb.3"` |  |
| addons.gitlabRunner.helmRepo.repoName | string | `"registry1"` |  |
| addons.gitlabRunner.helmRepo.chartName | string | `"gitlab-runner"` |  |
| addons.gitlabRunner.helmRepo.tag | string | `"0.77.2-bb.3"` |  |
| addons.gitlabRunner.flux | object | `{}` | Flux reconciliation overrides specifically for the Gitlab Runner Package |
| addons.gitlabRunner.values | object | `{}` | Values to passthrough to the gitlab runner chart: https://repo1.dso.mil/big-bang/product/packages/gitlab-runner.git |
| addons.gitlabRunner.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| addons.nexusRepositoryManager.enabled | bool | `false` | Toggle deployment of Nexus Repository Manager. |
| addons.nexusRepositoryManager.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.nexusRepositoryManager.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/nexus.git"` |  |
| addons.nexusRepositoryManager.git.path | string | `"./chart"` |  |
| addons.nexusRepositoryManager.git.tag | string | `"81.1.0-bb.0"` |  |
| addons.nexusRepositoryManager.helmRepo.repoName | string | `"registry1"` |  |
| addons.nexusRepositoryManager.helmRepo.chartName | string | `"nexus-repository-manager"` |  |
| addons.nexusRepositoryManager.helmRepo.tag | string | `"81.1.0-bb.0"` |  |
| addons.nexusRepositoryManager.license_key | string | `""` | Base64 encoded license file. |
| addons.nexusRepositoryManager.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| addons.nexusRepositoryManager.sso.enabled | bool | `false` | Toggle SAML SSO for NXRM. -- handles SAML SSO, a Client must be configured in Keycloak or IdP -- to complete setup. -- https://support.sonatype.com/hc/en-us/articles/1500000976522-SAML-integration-for-Nexus-Repository-Manager-Pro-3-and-Nexus-IQ-Server-with-Keycloak#h_01EV7CWCYH3YKAPMAHG8XMQ599 |
| addons.nexusRepositoryManager.sso.idp_data | object | `{"email":"","entityId":"","firstName":"","groups":"","lastName":"","username":""}` | NXRM SAML SSO Integration data |
| addons.nexusRepositoryManager.sso.idp_data.username | string | `""` | IdP Field Mappings -- NXRM username attribute |
| addons.nexusRepositoryManager.sso.idp_data.firstName | string | `""` | NXRM firstname attribute (optional) |
| addons.nexusRepositoryManager.sso.idp_data.lastName | string | `""` | NXRM lastname attribute (optional) |
| addons.nexusRepositoryManager.sso.idp_data.email | string | `""` | NXRM email attribute (optional) |
| addons.nexusRepositoryManager.sso.idp_data.groups | string | `""` | NXRM groups attribute (optional) |
| addons.nexusRepositoryManager.sso.role | list | `[{"description":"","id":"","name":"","privileges":[],"roles":[]}]` | NXRM Role |
| addons.nexusRepositoryManager.flux | object | `{}` | Flux reconciliation overrides specifically for the Nexus Repository Manager Package |
| addons.nexusRepositoryManager.values | object | `{}` | Values to passthrough to the nxrm chart: https://repo1.dso.mil/big-bang/product/packages/nexus.git |
| addons.nexusRepositoryManager.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| addons.sonarqube.enabled | bool | `false` | Toggle deployment of SonarQube. |
| addons.sonarqube.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.sonarqube.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/sonarqube.git"` |  |
| addons.sonarqube.git.path | string | `"./chart"` |  |
| addons.sonarqube.git.tag | string | `"2025.1.0-bb.0"` |  |
| addons.sonarqube.helmRepo.repoName | string | `"registry1"` |  |
| addons.sonarqube.helmRepo.chartName | string | `"sonarqube"` |  |
| addons.sonarqube.helmRepo.tag | string | `"2025.1.0-bb.0"` |  |
| addons.sonarqube.flux | object | `{}` | Flux reconciliation overrides specifically for the Sonarqube Package |
| addons.sonarqube.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| addons.sonarqube.sso.enabled | bool | `false` | Toggle SAML SSO for SonarQube. Enabling this option will auto-create any required secrets. |
| addons.sonarqube.sso.client_id | string | `""` | SonarQube SAML client ID |
| addons.sonarqube.sso.login | string | `"login"` | SonarQube login sso attribute. |
| addons.sonarqube.sso.name | string | `"name"` | SonarQube name sso attribute. |
| addons.sonarqube.sso.email | string | `"email"` | SonarQube email sso attribute. |
| addons.sonarqube.sso.group | string | `"group"` | (optional) SonarQube group sso attribute. |
| addons.sonarqube.database.host | string | `""` | Hostname of a pre-existing PostgreSQL database to use for SonarQube. |
| addons.sonarqube.database.port | int | `5432` | Port of a pre-existing PostgreSQL database to use for SonarQube. |
| addons.sonarqube.database.database | string | `""` | Database name to connect to on host. |
| addons.sonarqube.database.username | string | `""` | Username to connect as to external database, the user must have all privileges on the database. |
| addons.sonarqube.database.password | string | `""` | Database password for the username used to connect to the existing database. |
| addons.sonarqube.values | object | `{}` | Values to passthrough to the sonarqube chart: https://repo1.dso.mil/big-bang/product/packages/sonarqube.git |
| addons.sonarqube.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| addons.fortify.enabled | bool | `false` | Toggle deployment of Fortify. |
| addons.fortify.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.fortify.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/fortify.git"` |  |
| addons.fortify.git.path | string | `"./chart"` |  |
| addons.fortify.git.tag | string | `"1.1.2320154-bb.31"` |  |
| addons.fortify.helmRepo.repoName | string | `"registry1"` |  |
| addons.fortify.helmRepo.chartName | string | `"fortify-ssc"` |  |
| addons.fortify.helmRepo.tag | string | `"1.1.2320154-bb.31"` |  |
| addons.fortify.flux | object | `{}` | Flux reconciliation overrides specifically for the Fortify Package |
| addons.fortify.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| addons.fortify.sso.enabled | bool | `false` | Toggle SSO for Fortify on and off |
| addons.fortify.sso.client_id | string | `""` | SAML Client ID to use for Fortify |
| addons.fortify.sso.client_secret | string | `""` | SAML Client Secret to use for Fortify |
| addons.fortify.values | object | `{}` | Values to passthrough to the fortify chart: https://repo1.dso.mil/big-bang/product/packages/fortify.git |
| addons.fortify.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| addons.haproxy.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.haproxy.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/haproxy.git"` |  |
| addons.haproxy.git.path | string | `"./chart"` |  |
| addons.haproxy.git.tag | string | `"1.19.3-bb.10"` |  |
| addons.haproxy.helmRepo.repoName | string | `"registry1"` |  |
| addons.haproxy.helmRepo.chartName | string | `"haproxy"` |  |
| addons.haproxy.helmRepo.tag | string | `"1.19.3-bb.10"` |  |
| addons.haproxy.flux | object | `{}` | Flux reconciliation overrides specifically for the HAProxy Package |
| addons.haproxy.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| addons.haproxy.values | object | `{}` | Values to passthrough to the haproxy chart: https://repo1.dso.mil/big-bang/product/packages/haproxy.git |
| addons.haproxy.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| addons.anchoreEnterprise.enabled | bool | `false` | Toggle deployment of Anchore. |
| addons.anchoreEnterprise.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.anchoreEnterprise.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/anchore-enterprise.git"` |  |
| addons.anchoreEnterprise.git.path | string | `"./chart"` |  |
| addons.anchoreEnterprise.git.tag | string | `"3.10.0-bb.0"` |  |
| addons.anchoreEnterprise.helmRepo.repoName | string | `"registry1"` |  |
| addons.anchoreEnterprise.helmRepo.chartName | string | `"anchore-enterprise"` |  |
| addons.anchoreEnterprise.helmRepo.tag | string | `"3.10.0-bb.0"` |  |
| addons.anchoreEnterprise.flux | object | `{"upgrade":{"disableWait":true}}` | Flux reconciliation overrides specifically for the Anchore Package |
| addons.anchoreEnterprise.adminPassword | string | `""` | Initial admin password used to authenticate to Anchore. |
| addons.anchoreEnterprise.enterprise | object | `{"licenseYaml":"FULL LICENSE\n"}` | Anchore Enterprise functionality. |
| addons.anchoreEnterprise.enterprise.licenseYaml | string | `"FULL LICENSE\n"` | License for Anchore Enterprise. Enterprise is the only option available for the chart starting with chart major version 2.X. For formatting examples see https://repo1.dso.mil/big-bang/product/packages/CHART.md#enabling-enterprise-services |
| addons.anchoreEnterprise.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| addons.anchoreEnterprise.sso.enabled | bool | `false` | Toggle SAML SSO for Anchore on and off. Enabling this option will auto-create any required secrets (Note: SSO requires an Enterprise license). |
| addons.anchoreEnterprise.sso.client_id | string | `""` | Anchore SAML client ID |
| addons.anchoreEnterprise.sso.role_attribute | string | `""` | Anchore SAML client role attribute |
| addons.anchoreEnterprise.database.host | string | `""` | Hostname of a pre-existing PostgreSQL database to use for Anchore. Entering connection info will disable the deployment of an internal database and will auto-create any required secrets. |
| addons.anchoreEnterprise.database.port | string | `""` | Port of a pre-existing PostgreSQL database to use for Anchore. |
| addons.anchoreEnterprise.database.username | string | `""` | Username to connect as to external database, the user must have all privileges on the database. |
| addons.anchoreEnterprise.database.password | string | `""` | Database password for the username used to connect to the existing database. |
| addons.anchoreEnterprise.database.database | string | `""` | Database name to connect to on host (Note: database name CANNOT contain hyphens). |
| addons.anchoreEnterprise.database.feeds_database | string | `""` | Feeds database name to connect to on host (Note: feeds database name CANNOT contain hyphens). Only required for enterprise edition of anchore. By default, feeds database will be configured with the same username and password as the main database. For formatting examples on how to use a separate username and password for the feeds database see https://repo1.dso.mil/big-bang/product/packages/CHART.md#handling-dependencies |
| addons.anchoreEnterprise.redis.host | string | `""` | Hostname of a pre-existing Redis to use for Anchore Enterprise. Entering connection info will enable external redis and will auto-create any required secrets. Anchore only requires redis for enterprise deployments and will not provision an instance if using external |
| addons.anchoreEnterprise.redis.port | string | `""` | Port of a pre-existing Redis to use for Anchore Enterprise. |
| addons.anchoreEnterprise.redis.username | string | `""` | OPTIONAL: Username to connect to a pre-existing Redis (for password-only auth leave empty) |
| addons.anchoreEnterprise.redis.password | string | `""` | Password to connect to pre-existing Redis. |
| addons.anchoreEnterprise.values | object | `{}` | Values to passthrough to the anchore chart: https://repo1.dso.mil/big-bang/product/packages/anchore-enterprise.git |
| addons.anchoreEnterprise.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| addons.mattermostOperator.enabled | bool | `false` | Toggle deployment of Mattermost Operator. |
| addons.mattermostOperator.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.mattermostOperator.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/mattermost-operator.git"` |  |
| addons.mattermostOperator.git.path | string | `"./chart"` |  |
| addons.mattermostOperator.git.tag | string | `"1.23.0-bb.0"` |  |
| addons.mattermostOperator.helmRepo.repoName | string | `"registry1"` |  |
| addons.mattermostOperator.helmRepo.chartName | string | `"mattermost-operator"` |  |
| addons.mattermostOperator.helmRepo.tag | string | `"1.23.0-bb.0"` |  |
| addons.mattermostOperator.flux | object | `{}` | Flux reconciliation overrides specifically for the Mattermost Operator Package |
| addons.mattermostOperator.values | object | `{}` | Values to passthrough to the mattermost operator chart: https://repo1.dso.mil/big-bang/product/packages/values.yaml |
| addons.mattermostOperator.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| addons.mattermost.enabled | bool | `false` | Toggle deployment of Mattermost. |
| addons.mattermost.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.mattermost.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/mattermost.git"` |  |
| addons.mattermost.git.path | string | `"./chart"` |  |
| addons.mattermost.git.tag | string | `"10.10.1-bb.0"` |  |
| addons.mattermost.helmRepo.repoName | string | `"registry1"` |  |
| addons.mattermost.helmRepo.chartName | string | `"mattermost"` |  |
| addons.mattermost.helmRepo.tag | string | `"10.10.1-bb.0"` |  |
| addons.mattermost.flux | object | `{"driftDetection":{"ignore":[{"paths":[""],"target":{"kind":"Mattermost"}},{"paths":[""],"target":{"kind":"Job"}},{"paths":[""],"target":{"kind":"StatefulSet"}}]}}` | Flux reconciliation overrides specifically for the Mattermost Package |
| addons.mattermost.enterprise | object | `{"enabled":false,"license":""}` | Mattermost Enterprise functionality. |
| addons.mattermost.enterprise.enabled | bool | `false` | Toggle the Mattermost Enterprise.  This must be accompanied by a valid license unless you plan to start a trial post-install. |
| addons.mattermost.enterprise.license | string | `""` | License for Mattermost. This should be the entire contents of the license file from Mattermost (should be one line), example below license: "eyJpZCI6InIxM205bjR3eTdkYjludG95Z3RiOD---REST---IS---HIDDEN |
| addons.mattermost.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| addons.mattermost.sso.enabled | bool | `false` | Toggle OIDC SSO for Mattermost on and off. Enabling this option will auto-create any required secrets. |
| addons.mattermost.sso.client_id | string | `""` | Mattermost OIDC client ID |
| addons.mattermost.sso.client_secret | string | `""` | Mattermost OIDC client secret |
| addons.mattermost.database.host | string | `""` | Hostname of a pre-existing PostgreSQL database to use for Mattermost. Entering connection info will disable the deployment of an internal database and will auto-create any required secrets. |
| addons.mattermost.database.port | string | `""` | Port of a pre-existing PostgreSQL database to use for Mattermost. |
| addons.mattermost.database.username | string | `""` | Username to connect as to external database, the user must have all privileges on the database. |
| addons.mattermost.database.password | string | `""` | Database password for the username used to connect to the existing database. |
| addons.mattermost.database.database | string | `""` | Database name to connect to on host. |
| addons.mattermost.database.ssl_mode | string | `""` | SSL Mode to use when connecting to the database. Allowable values for this are viewable in the postgres documentation: https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-SSLMODE-STATEMENTS |
| addons.mattermost.objectStorage.endpoint | string | `""` | S3 compatible endpoint to use for connection information. Entering connection info will enable this option and will auto-create any required secrets. examples: "s3.amazonaws.com" "s3.us-gov-west-1.amazonaws.com" "minio.minio.svc.cluster.local:9000" |
| addons.mattermost.objectStorage.accessKey | string | `""` | Access key for connecting to object storage endpoint. |
| addons.mattermost.objectStorage.accessSecret | string | `""` | Secret key for connecting to object storage endpoint. Unencoded string data. This should be placed in the secret values and then encrypted |
| addons.mattermost.objectStorage.bucket | string | `""` | Bucket name to use for Mattermost - will be auto-created. |
| addons.mattermost.elasticsearch | object | `{"enabled":false}` | Mattermost Elasticsearch integration - requires enterprise E20 license - https://docs.mattermost.com/deployment/elasticsearch.html Connection info defaults to the BB deployed Elastic, all values can be overridden via the "values" passthrough for other connections. See values spec in MM chart "elasticsearch" yaml block - https://repo1.dso.mil/big-bang/product/packages/values.yaml |
| addons.mattermost.elasticsearch.enabled | bool | `false` | Toggle interaction with Elastic for optimized search indexing |
| addons.mattermost.values | object | `{}` | Values to passthrough to the Mattermost chart: https://repo1.dso.mil/big-bang/product/packages/values.yaml |
| addons.mattermost.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| addons.velero.enabled | bool | `false` | Toggle deployment of Velero. |
| addons.velero.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.velero.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/velero.git"` |  |
| addons.velero.git.path | string | `"./chart"` |  |
| addons.velero.git.tag | string | `"10.0.7-bb.0"` |  |
| addons.velero.helmRepo.repoName | string | `"registry1"` |  |
| addons.velero.helmRepo.chartName | string | `"velero"` |  |
| addons.velero.helmRepo.tag | string | `"10.0.7-bb.0"` |  |
| addons.velero.flux | object | `{}` | Flux reconciliation overrides specifically for the Velero Package |
| addons.velero.plugins | list | `[]` | Plugin provider for Velero - requires at least one plugin installed. Current supported values: aws, azure, csi |
| addons.velero.values | object | `{}` | Values to passthrough to the Velero chart: https://repo1.dso.mil/big-bang/product/packages/values.yaml |
| addons.velero.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| addons.keycloak.enabled | bool | `false` | Toggle deployment of Keycloak. if you enable Keycloak you should uncomment the istio passthrough configurations above istio.ingressGateways.passthrough-ingressgateway and istio.gateways.passthrough |
| addons.keycloak.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.keycloak.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/keycloak.git"` |  |
| addons.keycloak.git.path | string | `"./chart"` |  |
| addons.keycloak.git.tag | string | `"7.0.1-bb.3"` |  |
| addons.keycloak.helmRepo.repoName | string | `"registry1"` |  |
| addons.keycloak.helmRepo.chartName | string | `"keycloak"` |  |
| addons.keycloak.helmRepo.tag | string | `"7.0.1-bb.3"` |  |
| addons.keycloak.database.host | string | `""` | Hostname of a pre-existing database to use for Keycloak. Entering connection info will disable the deployment of an internal database and will auto-create any required secrets. |
| addons.keycloak.database.type | string | `"postgres"` | Pre-existing database type (e.g. postgres) to use for Keycloak. |
| addons.keycloak.database.port | int | `5432` | Port of a pre-existing database to use for Keycloak. |
| addons.keycloak.database.database | string | `""` | Database name to connect to on host. |
| addons.keycloak.database.username | string | `""` | Username to connect as to external database, the user must have all privileges on the database. |
| addons.keycloak.database.password | string | `""` | Database password for the username used to connect to the existing database. |
| addons.keycloak.flux | object | `{}` | Flux reconciliation overrides specifically for the OPA Gatekeeper Package |
| addons.keycloak.ingress | object | `{"cert":"","gateway":"","key":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| addons.keycloak.ingress.key | string | `""` | Certificate/Key pair to use as the certificate for exposing Keycloak Setting the ingress cert here will automatically create the volume and volumemounts in the Keycloak Package chart |
| addons.keycloak.values | object | `{}` | Values to passthrough to the keycloak chart: https://repo1.dso.mil/big-bang/product/packages/keycloak.git |
| addons.keycloak.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| addons.vault.enabled | bool | `false` | Toggle deployment of Vault. |
| addons.vault.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.vault.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/vault.git"` |  |
| addons.vault.git.path | string | `"./chart"` |  |
| addons.vault.git.tag | string | `"0.30.0-bb.9"` |  |
| addons.vault.helmRepo.repoName | string | `"registry1"` |  |
| addons.vault.helmRepo.chartName | string | `"vault"` |  |
| addons.vault.helmRepo.tag | string | `"0.30.0-bb.9"` |  |
| addons.vault.flux | object | `{"driftDetection":{"ignore":[{"paths":[""],"target":{"kind":"MutatingWebhookConfiguration"}},{"paths":[""],"target":{"kind":"Job"}},{"paths":[""],"target":{"kind":"StatefulSet"}}]}}` | Flux reconciliation overrides specifically for the Vault Package |
| addons.vault.ingress | object | `{"cert":"","gateway":"","key":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| addons.vault.ingress.key | string | `""` | Certificate/Key pair to use as the certificate for exposing Vault Setting the ingress cert here will automatically create the volume and volumemounts in the Vault package chart |
| addons.vault.values | object | `{}` | Values to passthrough to the vault chart: https://repo1.dso.mil/big-bang/product/packages/vault.git |
| addons.vault.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| addons.metricsServer.enabled | string | `"auto"` | Toggle deployment of metrics server Acceptable options are enabled: true, enabled: false, enabled: auto true = enabled / false = disabled / auto = automatic (Installs only if metrics API endpoint is not present) |
| addons.metricsServer.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.metricsServer.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/metrics-server.git"` |  |
| addons.metricsServer.git.path | string | `"./chart"` |  |
| addons.metricsServer.git.tag | string | `"3.12.2-bb.5"` |  |
| addons.metricsServer.helmRepo.repoName | string | `"registry1"` |  |
| addons.metricsServer.helmRepo.chartName | string | `"metrics-server"` |  |
| addons.metricsServer.helmRepo.tag | string | `"3.12.2-bb.5"` |  |
| addons.metricsServer.automountServiceAccountToken | bool | `true` | Enabled automount Service Account Token so that metrics-server fetches resource metrics from the kubelets |
| addons.metricsServer.flux | object | `{}` | Flux reconciliation overrides specifically for the metrics server Package |
| addons.metricsServer.values | object | `{}` | Values to passthrough to the metrics server chart: https://repo1.dso.mil/big-bang/product/packages/metrics-server.git |
| addons.metricsServer.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| addons.harbor.enabled | bool | `false` | Toggle deployment of harbor |
| addons.harbor.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.harbor.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/harbor.git"` |  |
| addons.harbor.git.tag | string | `"1.17.1-bb.2"` |  |
| addons.harbor.git.path | string | `"./chart"` |  |
| addons.harbor.helmRepo.repoName | string | `"registry1"` |  |
| addons.harbor.helmRepo.chartName | string | `"harbor"` |  |
| addons.harbor.helmRepo.tag | string | `"1.17.1-bb.2"` |  |
| addons.harbor.flux | object | `{}` | Flux reconciliation overrides specifically for the Harbor Package |
| addons.harbor.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| addons.harbor.values | object | `{}` | Values to pass through to Habor chart: https://repo1.dso.mil/big-bang/product/packages/harbor.git |
| addons.harbor.postRenderers | list | `[]` | Post Renderers.  See docs/postrenders.md |
| addons.thanos.enabled | bool | `false` | Toggle deployment of thanos |
| addons.thanos.sso.enabled | bool | `false` | Toggle SSO for Thanos on and off |
| addons.thanos.sso.client_id | string | `""` | OIDC Client ID to use for Thanos |
| addons.thanos.sso.client_secret | string | `""` | OIDC Client Secret to use for Thanos |
| addons.thanos.objectStorage.endpoint | string | `""` | S3 compatible endpoint to use for connection information. examples: "s3.amazonaws.com" "s3.us-gov-west-1.amazonaws.com" "minio.minio.svc.cluster.local:9000" Note: Thanos does not require protocol prefix for URL. |
| addons.thanos.objectStorage.region | string | `""` | S3 compatible region to use for connection information. |
| addons.thanos.objectStorage.accessKey | string | `""` | Access key for connecting to object storage endpoint. |
| addons.thanos.objectStorage.accessSecret | string | `""` | Secret key for connecting to object storage endpoint. Unencoded string data. This should be placed in the secret values and then encrypted |
| addons.thanos.objectStorage.bucket | string | `""` | Bucket Name for Thanos examples: "Thanos-metrics" |
| addons.thanos.objectStorage.insecure | bool | `false` | Whether or not objectStorage connection should require HTTPS, if connecting to in-cluster object |
| addons.thanos.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.thanos.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/thanos.git"` |  |
| addons.thanos.git.tag | string | `"16.0.2-bb.0"` |  |
| addons.thanos.git.path | string | `"./chart"` |  |
| addons.thanos.helmRepo.repoName | string | `"registry1"` |  |
| addons.thanos.helmRepo.chartName | string | `"thanos"` |  |
| addons.thanos.helmRepo.tag | string | `"16.0.2-bb.0"` |  |
| addons.thanos.flux | object | `{"driftDetection":{"ignore":[{"paths":[""],"target":{"kind":"Tenant"}},{"paths":[""],"target":{"kind":"Job"}},{"paths":[""],"target":{"kind":"StatefulSet"}}]}}` | Flux reconciliation overrides specifically for the Thanos Package |
| addons.thanos.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| addons.thanos.values | object | `{}` |  |
| addons.thanos.postRenderers | list | `[]` |  |
| addons.externalSecrets.enabled | bool | `false` | Toggle deployment of external secrets |
| addons.externalSecrets.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.externalSecrets.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/external-secrets.git"` |  |
| addons.externalSecrets.git.tag | string | `"0.18.2-bb.0"` |  |
| addons.externalSecrets.git.path | string | `"./chart"` |  |
| addons.externalSecrets.helmRepo.repoName | string | `"registry1"` |  |
| addons.externalSecrets.helmRepo.chartName | string | `"external-secrets"` |  |
| addons.externalSecrets.helmRepo.tag | string | `"0.18.2-bb.0"` |  |
| addons.externalSecrets.flux | object | `{}` | Override flux settings for this package |
| addons.externalSecrets.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| addons.externalSecrets.values | object | `{}` |  |
| addons.externalSecrets.postRenderers | list | `[]` |  |
| addons.mimir.enabled | bool | `false` | Toggle deployment of Mimir |
| addons.mimir.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.mimir.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/mimir.git"` |  |
| addons.mimir.git.tag | string | `"5.7.0-bb.3"` |  |
| addons.mimir.git.path | string | `"./chart"` |  |
| addons.mimir.helmRepo.repoName | string | `"registry1"` |  |
| addons.mimir.helmRepo.chartName | string | `"mimir"` |  |
| addons.mimir.helmRepo.tag | string | `"5.7.0-bb.3"` |  |
| addons.mimir.enterprise | object | `{"enabled":false}` | Enable Mimir Enterprise |
| addons.mimir.minioObjectStorage | object | `{"configSecret":{"accessKey":"minio","secretKey":"minio123"},"defaultUserCredentials":{"password":"supersecret","username":"mimir-user"},"enabled":false}` | Enable Big Bang MinIO dependency chart for Mimir |
| addons.mimir.minioObjectStorage.configSecret | object | `{"accessKey":"minio","secretKey":"minio123"}` | MinIO root credentials |
| addons.mimir.s3ObjectStorage | object | `{"accessKey":"","accessSecret":"","bucketName":"","enabled":false,"endpoint":"","insecure":false,"region":""}` | Configure Mimir to use S3 bucket |
| addons.mimir.s3ObjectStorage.region | string | `""` | S3 compatible region to use for connection information. |
| addons.mimir.s3ObjectStorage.accessKey | string | `""` | Access key for connecting to object storage endpoint. If using IRSA annotation this should be left blank. |
| addons.mimir.s3ObjectStorage.accessSecret | string | `""` | Secret key for connecting to object storage endpoint. If using IRSA annotation this should be left blank. Unencoded string data. This should be placed in the secret values and then encrypted |
| addons.mimir.s3ObjectStorage.bucketName | string | `""` | Bucket name for the Mimir bucket as YAML |
| addons.mimir.s3ObjectStorage.insecure | bool | `false` | Whether or not objectStorage connection should require HTTPS, if connecting to in-cluster object |
| addons.mimir.serviceAccountAnnotations | object | `{}` | Mimir Service Account Annotations |
| addons.mimir.values | object | `{}` |  |
| addons.mimir.postRenderers | list | `[]` |  |
| addons.mimir.flux | object | `{}` | Flux reconciliation overrides specifically for the alloy package |
| addons.headlamp.enabled | bool | `false` | Toggle deployment of headlamp |
| addons.headlamp.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| addons.headlamp.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/headlamp.git"` |  |
| addons.headlamp.git.tag | string | `"0.32.1-bb.2"` |  |
| addons.headlamp.git.path | string | `"./chart"` |  |
| addons.headlamp.helmRepo.repoName | string | `"registry1"` |  |
| addons.headlamp.helmRepo.chartName | string | `"headlamp"` |  |
| addons.headlamp.helmRepo.tag | string | `"0.32.1-bb.2"` |  |
| addons.headlamp.flux | object | `{}` | Override flux settings for this package |
| addons.headlamp.ingress | object | `{"gateway":""}` | Redirect the package ingress to a specific Istio Gateway (listed in `istio.gateways`).  The default is "public". |
| addons.headlamp.sso.enabled | bool | `false` | Toggle OIDC SSO for Headlamp on and off. Enabling this option will auto-create any required secrets. |
| addons.headlamp.sso.client_id | string | `""` | Headlamp OIDC client ID |
| addons.headlamp.sso.client_secret | string | `""` | Headlamp OIDC client secret |
| addons.headlamp.values | object | `{}` |  |
| addons.headlamp.postRenderers | list | `[]` |  |
| wrapper | object | `{"git":{"path":"chart","repo":"https://repo1.dso.mil/big-bang/product/packages/wrapper.git","tag":"0.4.15"},"helmRepo":{"chartName":"wrapper","repoName":"registry1","tag":"0.4.15"},"sourceType":"git"}` | Wrapper chart for integrating Big Bang components alongside a package |
| wrapper.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| wrapper.helmRepo.repoName | string | `"registry1"` | Repository holding OCI chart, corresponding to `helmRepositories` name |
| wrapper.helmRepo.chartName | string | `"wrapper"` | Name of the OCI chart in `repo` |
| wrapper.helmRepo.tag | string | `"0.4.15"` | Tag of the OCI chart in `repo` |
| wrapper.git.repo | string | `"https://repo1.dso.mil/big-bang/product/packages/wrapper.git"` | Git repo holding the wrapper helm chart, example: https://repo1.dso.mil/big-bang/product/packages/wrapper |
| wrapper.git.path | string | `"chart"` | Path inside of the git repo to find the helm chart, example: chart |
| wrapper.git.tag | string | `"0.4.15"` | Git tag to check out.  Takes precedence over branch. [More info](https://fluxcd.io/flux/components/source/gitrepositories/#reference), example: 0.0.2 |
| packages | object | `{"sample":{"configMaps":{},"dependsOn":[],"enabled":false,"flux":{},"git":{"branch":null,"commit":null,"credentials":{"caFile":"","knownHosts":"","password":"","privateKey":"","publicKey":"","username":""},"existingSecret":"","path":null,"repo":null,"semver":null,"tag":null},"helmRepo":{"chartName":null,"repoName":null,"tag":null},"istio":{},"kustomize":false,"monitor":{},"network":{},"postRenderers":[],"secrets":{},"sourceType":"git","values":{},"wrapper":{"enabled":false,"postRenderers":[]}}}` | Packages to deploy with Big Bang @default - '{}' |
| packages.sample | object | Uses `defaults/<package name>.yaml` for defaults.  See `package` Helm chart for additional values that can be set. | Package name.  Each package will be independently wrapped for Big Bang integration. |
| packages.sample.enabled | bool | true | Toggle deployment of this package |
| packages.sample.sourceType | string | `"git"` | Choose source type of "git" or "helmRepo" |
| packages.sample.wrapper | object | false | Toggle wrapper functionality. See https://docs-bigbang.dso.mil/latest/docs/guides/deployment-scenarios/extra-package-deployment/#Wrapper-Deployment for more details. |
| packages.sample.wrapper.postRenderers | list | `[]` | After deployment, patch wrapper resources.  [More info](https://fluxcd.io/flux/components/helm/helmreleases/#post-renderers) |
| packages.sample.kustomize | bool | `false` | Use a kustomize deployment rather than Helm |
| packages.sample.helmRepo | object | `{"chartName":null,"repoName":null,"tag":null}` | HelmRepo source is supported as an option for Helm deployments. If both `git` and `helmRepo` are provided `git` will take precedence. |
| packages.sample.helmRepo.repoName | string | `nil` | Name of the HelmRepo specified in `helmRepositories` |
| packages.sample.helmRepo.chartName | string | `nil` | Name of the chart stored in the Helm repository |
| packages.sample.helmRepo.tag | string | `nil` | Tag of the chart in the Helm repo, required |
| packages.sample.git | object | `{"branch":null,"commit":null,"credentials":{"caFile":"","knownHosts":"","password":"","privateKey":"","publicKey":"","username":""},"existingSecret":"","path":null,"repo":null,"semver":null,"tag":null}` | Git source is supported for both Helm and Kustomize deployments. If both `git` and `helmRepo` are provided `git` will take precedence. |
| packages.sample.git.repo | string | `nil` | Git repo URL holding the helm chart for this package, required if using git |
| packages.sample.git.commit | string | `nil` | Git commit to check out.  Takes precedence over semver, tag, and branch. [More info](https://fluxcd.io/flux/components/source/gitrepositories/#reference) |
| packages.sample.git.semver | string | `nil` | Git semVer tag expression to check out.  Takes precedence over tag. [More info](https://fluxcd.io/flux/components/source/gitrepositories/#reference) |
| packages.sample.git.tag | string | `nil` | Git tag to check out.  Takes precedence over branch. [More info](https://fluxcd.io/flux/components/source/gitrepositories/#reference) |
| packages.sample.git.branch | string | `nil` | Git branch to check out.  [More info](https://fluxcd.io/flux/components/source/gitrepositories/#reference). |
| packages.sample.git.path | string | `nil` | Path inside of the git repo to find the helm chart or kustomize |
| packages.sample.git.existingSecret | string | `""` | Optional, alternative existing secret to use for git credentials, must be in the appropriate format: https://toolkit.fluxcd.io/components/source/gitrepositories/#https-authentication |
| packages.sample.git.credentials | object | `{"caFile":"","knownHosts":"","password":"","privateKey":"","publicKey":"","username":""}` | Optional, alternative Chart created secrets with user defined values |
| packages.sample.git.credentials.username | string | `""` | HTTP git credentials, both username and password must be provided |
| packages.sample.git.credentials.caFile | string | `""` | HTTPS certificate authority file.  Required for any repo with a self signed certificate |
| packages.sample.git.credentials.privateKey | string | `""` | SSH git credentials, privateKey, publicKey, and knownHosts must be provided |
| packages.sample.flux | object | `{}` | Override flux settings for this package |
| packages.sample.postRenderers | list | `[]` | After deployment, patch package resources.  [More info](https://fluxcd.io/flux/components/helm/helmreleases/#post-renderers) |
| packages.sample.dependsOn | list | `[]` | Specify dependencies for the package. Only used for HelmRelease, does not effect Kustomization. See [here](https://fluxcd.io/flux/components/helm/helmreleases/#helmrelease-dependencies) for a reference. |
| packages.sample.istio | object | `{}` | Package details for Istio.  See [wrapper values](https://repo1.dso.mil/big-bang/product/packages/wrapper/-/blob/main/chart/values.yaml) for settings. |
| packages.sample.monitor | object | `{}` | Package details for monitoring.  See [wrapper values](https://repo1.dso.mil/big-bang/product/packages/wrapper/-/blob/main/chart/values.yaml) for settings. |
| packages.sample.network | object | `{}` | Package details for network policies.  See [wrapper values](https://repo1.dso.mil/big-bang/product/packages/wrapper/-/blob/main/chart/values.yaml) for settings. |
| packages.sample.secrets | object | `{}` | Secrets that should be created prior to package installation.  See [wrapper values](https://repo1.dso.mil/big-bang/product/packages/wrapper/-/blob/main/chart/values.yaml) for settings. |
| packages.sample.configMaps | object | `{}` | ConfigMaps that should be created prior to package installation.  See [wrapper values](https://repo1.dso.mil/big-bang/product/packages/wrapper/-/blob/main/chart/values.yaml) for settings. |
| packages.sample.values | object | `{}` | Values to pass through to package Helm chart |
