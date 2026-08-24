# Keycloak Production Considerations

[[_TOC_]]

The Keycloak package includes a PostgreSQL dependency for development and CI. It is enabled by default and is not suitable for production. Supplying an external database host through the Big Bang convenience values disables the bundled PostgreSQL chart.

## Configure an External Database

```yaml
addons:
  keycloak:
    enabled: true
    database:
      type: postgres
      host: postgresql.example.svc.cluster.local
      port: 5432
      database: keycloak
      username: keycloak
      password: "<encrypted-or-injected-password>"
```

Protect the database password with SOPS or another secret-management workflow. Restrict `networkPolicies.egress.definitions.database-subnets` to the actual database CIDRs and port instead of retaining broad default private-network ranges.

## Configure TLS Passthrough

Keycloak must terminate TLS for X.509 client authentication such as CAC authentication. Select a passthrough gateway and provide a certificate and key through the Big Bang values:

```yaml
addons:
  keycloak:
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
```

The certificate must cover `keycloak.<domain>`. Store private key material in an encrypted values file or manage the resulting Secret through an approved external secret system.

## Replace Default Administrator Credentials

The package defaults are development credentials and must be replaced before production use:

```yaml
addons:
  keycloak:
    values:
      upstream:
        secrets:
          env:
            stringData:
              KEYCLOAK_ADMIN: "<administrator-name>"
              KEYCLOAK_ADMIN_PASSWORD: "<encrypted-or-injected-password>"
```

Prefer a separately managed administrative identity after bootstrap, restrict use of the bootstrap administrator, and rotate its credentials according to the environment's policy.

## Configure Availability and Capacity

The package deploys one Keycloak replica by default. Production environments should select a replica count, resources, scheduling constraints, and disruption behavior that meet their availability objectives. The package configures the headless service and JGroups DNS discovery used by Keycloak's distributed cache.

```yaml
addons:
  keycloak:
    values:
      upstream:
        replicas: 3
        resources:
          requests:
            cpu: "<measured-request>"
            memory: "<measured-request>"
          limits:
            memory: "<measured-limit>"
```

Test rolling upgrades, node loss, database failover, cache behavior, and session continuity with the selected topology. Back up the external database and test restoration together with realm configuration, providers, themes, and any custom extensions.

## Preserve Big Bang Overrides

The upstream Keycloak chart represents `extraEnv`, `extraEnvFrom`, `extraVolumes`, and `extraVolumeMounts` as templated strings. Overrides replace the complete value rather than merging individual entries. If you override one of these fields through `addons.keycloak.values.upstream`, preserve every Big Bang-provided entry you still require. See the package's [configuration documentation](https://repo1.dso.mil/big-bang/product/packages/keycloak/-/blob/main/docs/CONFIGURATION.md) for supported examples.
