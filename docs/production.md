# Big Bang Production Configuration

[[_TOC_]]

## Gatekeeper
The gatekeeper `values` section should resemble below when deploying to production.

```yaml
# OPA Gatekeeper
#
gatekeeper:
  # -- Toggle deployment of OPA Gatekeeper.
  enabled: true
  git:
    repo: https://repo1.dso.mil/platform-one/big-bang/apps/core/policy.git
    path: "./chart"
    tag: "3.5.1-bb.2"

  # -- Flux reconciliation overrides specifically for the OPA Gatekeeper Package
  flux: {}

  # -- Values to passthrough to the gatekeeper chart: https://repo1.dso.mil/platform-one/big-bang/apps/core/policy.git
  values:
      violations:
        allowedDockerRegistries:
          match:
            excludedNamespaces: 
              - kube-system # ignored as the kubernetes distro cannot be controlled

  # -- Post Renderers.  See docs/postrenders.md
  postRenderers: []
```

To validate it was deployed correctly on your cluster run the following command:

`kubectl get k8sallowedrepos.constraints.gatekeeper.sh/allowed-docker-registries -o yaml`

You should only see `kube-system` under `excludedNamespaces` section.

Output:

```yaml
  name: allowed-docker-registries
  resourceVersion: "10390"
  uid: b51b3887-3cf8-4495-b37e-fb8ef31755db
spec:
  enforcementAction: deny
  match:
    excludedNamespaces:
    - kube-system
    kinds:
    - apiGroups:
      - ""
      kinds:
      - Pod
  parameters:
    exemptContainers: []
    repos:
    - registry1.dso.mil
    - registry.dso.mil
```

## Gitlab
This section provides suggested settings for Gitlab operational/production environments.

### Use external database service
For production deployments you must externalize the database service. BigBang will pass through the most common value overrides to the Gitlab Package chart.   
Disable the internal postgres by configuring an external database in the BigBang values.
```yaml
addons:
  gitlab: 
    database:
      host:
      port:
      database:
      username:
      password:
```

### Use external object storage 
For production deployments you must externalize object storage service. BigBang will pass through the most common value overrides to the Gitlab Package chart.  
Disable the internal MinIO instance by configuring an external object storage service.
```yaml
addons:
  gitlab:
    objectStorage:
      type:
      endpoint:
      region:
      accessKey:
      accessSecret:
      bucketPrefix:
      iamProfile:
```

### Flux settings
Large Gitlab installations should increase the Gitlab specific HelmRelease timeout value to around 30m to 45m and the Gitlab specific HelmRelease retries value should be adjusted to around 8 to 10.
```yaml
addons:
  gitlab:
    flux:
      timeout: 30m
      upgrade:
        remediation:
          retries: 8
```

### Kubernetes resource request/limit settings
K8s resource requests/limits for webservice and gitaly workloads should be increased from the defaults. Gitlab engineers state predicting Gitaly's resource consumption is very difficult, and will require testing to find the applicable limits/requests for each individual installation. See this [Gitlab Epic](https://gitlab.com/groups/gitlab-org/-/epics/6127) for more information. See the [gitlab/docs/k8s-resources.md](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab/-/blob/main/docs/k8s-resources.md) for a list of all possible configuration values. Use BigBang values overrides to change the Gitlab resource settings.  
Recommended starting point:
```yaml
addons:
  gitlab:
    values:
      gitlab:
        webservice:
          resources:
            limits:
              cpu: 2
              memory: 4G
            requests:
              cpu: 2
              memory: 4G
        gitaly:
          resources:
            limits:
              cpu: 2
              memory: 4G
            requests:
              cpu: 2
              memory: 4G
```

### Backup and rename gitlab-rails-secret
An operational deployment of Gitlab should backup and re-create the Gitlab Rails Encryption information as a secret with a different name as [documented here](https://docs.gitlab.com/charts/installation/secrets.html#gitlab-rails-secret). Using a custom secret name can help prevent accidental overwriting. 
To make the secret creation easier, the existing secret can be copied and modified with a different name.
```bash
kubectl get secret/gitlab-rails-secret -n gitlab -o yaml > gitlab-rails-custom-secret.yaml
```
Edit the file and change the name of the secret. Example:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-rails-custom-secret
```
Use GitOps configuration as code (CaC) and commit the custom rails secret to your GitOps repository. You should encrypt the custom rails secret keys in the GitOps repository to preserve security. 
Then the following Gitlab helm chart value `global.railsSecrets.secret` can be overridden to point to the custom rails secret.
```yaml
addons:
  gitlab:
    values:
      global:
        railsSecrets:
          secret:  gitlab-rails-custom-secret
```
The custom rails secret should be backed up somewhere secure outside the cluster if not included in your GitOps code repository.

**If the Kubernetes gitlab-rails-secret happens to get overwritten Gitlab will no longer be able to access the encrypted data in the database.**

You will get errors like this in the logs.
```text
OpenSSL::Cipher::CipherError ()
```
Many things break when this happens and the recovery is ugly with serious user impacts.  

At a minimum an operational deployment of Gitlab should export and save the gitlab-rails-secret somewhere secure outside the cluster.
```bash
kubectl get secret/gitlab-rails-secret -n gitlab -o yaml > cya.yaml
```

## Vault
This section provides suggested settings for Vault operational/production environments. Vault is a large complicated application and has many options that cannot adequately be covered here. Vault has significant security risks if not properly configured and administrated. Please consult the upstream [Vault documentation](https://learn.hashicorp.com/tutorials/vault/kubernetes-raft-deployment-guide?in=vault/kubernetes#configure-vault-helm-chart) as the ultimate authority. The following is an example operational/production config using a passthrough istio ingress gateway, high availability, auto-unseal, and raft for distributed filesystem persistence. Consult the BigBang Vault Package helm repo [/docs/production-ha.md](https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/vault/-/blob/main/docs/production-ha.md) for more information.
```yaml
istio:
  enabled: true

  ingressGateways:
    passthrough-ingressgateway:
      type: "LoadBalancer"
      # nodePortBase: 30200

  gateways:
    passthrough:
      ingressGateway: "passthrough-ingressgateway"
      hosts:
      - "*.{{ .Values.domain }}"
      tls:
        mode: "PASSTHROUGH"

addons:
  vault:
    enabled: true
    ingress:
      gateway: "passthrough"
      # provide the Vault TLS cert and key. BigBang will create the secret and volumemount for you
      # Leave blank to create your own secret and provide values for your own volume and volumemount
      key: |
        -----BEGIN PRIVATE KEY-----
        xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        -----END PRIVATE KEY-----
      cert: |
        -----BEGIN CERTIFICATE-----
        xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        -----END CERTIFICATE-----

    values:
      # disable autoInit. It should not be used for operations.
      autoInit:
        enabled: false

      global:
        # this is a double negative. Put "false" to enable TLS for passthrough ingress
        tlsDisable: false

      injector:
        extraEnvironmentVars:
          AGENT_INJECT_VAULT_ADDR: "https://vault.bigbang.dev"

      server:
        # Increase default resources
        resources:
          requests:
            memory: 8Gi
            cpu: 2000m
          limits:
            memory: 8Gi
            cpu: 2000m

        # disable the Vault provided ingress so that Istio ingress can be used.
        ingress:
          enabled: false

        # Extra environment variable to support high availability
        extraEnvironmentVars:
          # the istio gateway domain
          VAULT_API_ADDR: https://vault.bigbang.dev
          VAULT_ADDR:  https://127.0.0.1:8200
          VAULT_SKIP_VERIFY: "true"
          VAULT_LOG_FORMAT: "json"
          VAULT_LICENSE: "your-license-key-goes-here"

        ha:
          # enable high availability.
          enabled: true
          replicas: 3

          # raft is the license free most simple solution for a distributed filesystem
          raft:
            enabled: true
            setNodeId: true

            # these values should be encrypted to prevent the kms_key_id from being revealed 
            config: |
              ui = true

              listener "tcp" {
                tls_disable = 0
                address = "[::]:8200"
                cluster_address = "[::]:8201"
                tls_cert_file = "/vault/tls/tls.crt"
                tls_key_file  = "/vault/tls/tls.key"
              }

              storage "raft" {
                path = "/vault/data"

                retry_join {
                  leader_api_addr = "https://vault-vault-0.vault-vault-internal:8200"
                  leader_client_cert_file = "/vault/tls/tls.crt"
                  leader_client_key_file = "/vault/tls/tls.key"
                  leader_tls_servername = "vault.bigbang.dev"
                }
        
                retry_join {
                  leader_api_addr = "https://vault-vault-1.vault-vault-internal:8200"
                  leader_client_cert_file = "/vault/tls/tls.crt"
                  leader_client_key_file = "/vault/tls/tls.key"
                  leader_tls_servername = "vault.bigbang.dev"
                }
        
                retry_join {
                  leader_api_addr = "https://vault-vault-2.vault-vault-internal:8200"
                  leader_client_cert_file = "/vault/tls/tls.crt"
                  leader_client_key_file = "/vault/tls/tls.key"
                  leader_tls_servername = "vault.bigbang.dev"
                }
              }

              seal "awskms" {
                region     = "us-gov-west-1"
                kms_key_id = "your-kms-key-goes-here"
                endpoint   = "https://kms.us-gov-west-1.amazonaws.com"
              }

              telemetry {
                prometheus_retention_time = "24h"
                disable_hostname = true
                unauthenticated_metrics_access = true
              }

              service_registration "kubernetes" {}
```