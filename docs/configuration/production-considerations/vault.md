# Vault Production Considerations

[[_TOC_]]

Vault holds security-critical state and should be designed and operated using the [upstream production guidance](https://developer.hashicorp.com/vault/docs/concepts/production-hardening) and the Big Bang Vault package's [production configuration](https://repo1.dso.mil/big-bang/product/packages/vault/-/blob/main/docs/production.md).

At minimum, a production deployment should:

- Disable Big Bang's development-only `autoInit` automation. It writes the root token and unseal material to a Kubernetes Secret.
- Run Vault in high-availability mode with integrated Raft storage or another supported production storage backend.
- Use auto-unseal and protect recovery keys outside the cluster.
- Terminate TLS at Vault. Big Bang's passthrough gateway can pass encrypted traffic directly to the Vault pods.
- Size persistent storage and resources for the environment, retain volumes during cluster or release recovery, and back up Raft state regularly.
- Enable and retain audit devices appropriate for the environment. The package enables audit storage by default, but operators must configure and monitor Vault audit devices.

## Configure High Availability with Raft

The following Big Bang example shows the relevant value paths for a three-node Raft deployment using AWS KMS auto-unseal. Replace the domain, certificate, storage, resource, and KMS settings for the environment.

```yaml
addons:
  vault:
    enabled: true
    ingress:
      gateway: passthrough
      key: |
        -----BEGIN PRIVATE KEY-----
        <private-key>
        -----END PRIVATE KEY-----
      cert: |
        -----BEGIN CERTIFICATE-----
        <certificate-chain>
        -----END CERTIFICATE-----

    values:
      autoInit:
        enabled: false

      upstream:
        global:
          tlsDisable: false

        server:
          dataStorage:
            enabled: true
            size: 50Gi
            mountPath: /vault/data
            accessMode: ReadWriteOnce

          auditStorage:
            enabled: true

          resources:
            requests:
              cpu: 2000m
              memory: 8Gi
            limits:
              cpu: 2000m
              memory: 8Gi

          ingress:
            enabled: false

          extraEnvironmentVars:
            VAULT_LOG_FORMAT: json

          ha:
            enabled: true
            replicas: 3
            apiAddr: https://vault.dev.bigbang.mil

            raft:
              enabled: true
              setNodeId: true
              config: |
                ui = true

                listener "tcp" {
                  tls_disable = false
                  address = "[::]:8200"
                  cluster_address = "[::]:8201"
                  tls_cert_file = "/vault/tls/tls.crt"
                  tls_key_file  = "/vault/tls/tls.key"
                  telemetry {
                    unauthenticated_metrics_access = true
                  }
                }

                storage "raft" {
                  path = "/vault/data"

                  retry_join {
                    leader_api_addr = "https://vault-vault-0.vault-vault-internal:8200"
                    leader_client_cert_file = "/vault/tls/tls.crt"
                    leader_client_key_file = "/vault/tls/tls.key"
                    leader_tls_servername = "vault.dev.bigbang.mil"
                  }

                  retry_join {
                    leader_api_addr = "https://vault-vault-1.vault-vault-internal:8200"
                    leader_client_cert_file = "/vault/tls/tls.crt"
                    leader_client_key_file = "/vault/tls/tls.key"
                    leader_tls_servername = "vault.dev.bigbang.mil"
                  }

                  retry_join {
                    leader_api_addr = "https://vault-vault-2.vault-vault-internal:8200"
                    leader_client_cert_file = "/vault/tls/tls.crt"
                    leader_client_key_file = "/vault/tls/tls.key"
                    leader_tls_servername = "vault.dev.bigbang.mil"
                  }
                }

                seal "awskms" {
                  region = "us-gov-west-1"
                  kms_key_id = "<kms-key-id>"
                  endpoint = "https://kms.us-gov-west-1.amazonaws.com"
                }

                telemetry {
                  prometheus_retention_time = "24h"
                  disable_hostname = true
                }

                service_registration "kubernetes" {}
```

The certificate must be valid for the name used by `apiAddr` and `leader_tls_servername`. The example intentionally does not set `VAULT_SKIP_VERIFY`; disabling TLS verification is not an appropriate production default. Configure `VAULT_LICENSE` only for a licensed Vault Enterprise deployment.

## Initialize and Protect Recovery Material

After installation, initialize Vault manually with `vault operator init`, store the recovery keys and initial root token in an approved system outside Kubernetes, and validate Raft snapshots and restore procedures.
