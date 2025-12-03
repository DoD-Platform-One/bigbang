# NXRM-HA (Nexus Repository Manager High Availability)

## Overview

NXRM-HA is the official Sonatype-supported Helm chart for deploying Nexus Repository Manager in production environments. This package replaces the legacy `nexus-repository-manager` chart and provides:

- **High Availability Support**: Deploy Nexus Repository Manager Pro in a highly available, multi-node configuration
- **Production-Ready Architecture**: Built-in support for external databases (PostgreSQL, AWS RDS) and object storage (S3, Azure Blob)
- **Enterprise Features**: Full support for Nexus Repository Manager Pro features including clustering, replication, and advanced security
- **Active Maintenance**: Direct support and updates from Sonatype, ensuring compatibility with the latest Nexus Repository Manager versions

Nexus provides a wealth of documentation [here](https://help.sonatype.com/repomanager3) with details about supported artifact formats, use cases, and more.

## Big Bang Touch Points

### Licensing

Nexus Repository Manager OSS is open-source,
[licensed under EPL 1.0](https://github.com/sonatype/nexus-public/blob/main/LICENSE.txt).

### UI

Nexus Repository Manager serves as the user interface for Nexus. Nexus Repository Manager provides optional anonymous access for users who need to search repositories, browse repositories and look through the system feeds. UI access is exposed through the Istio Virtual Service.

### Logging

You can configure the level of logging for the repository manager and all plugins as well as inspect the current log using the user interface. Logging can be enabled by clicking on the Logging menu item in the Administration submenu in the main menu. Logs are auto-scraped and shipped via your chosen logging stack when deployed with Big Bang.

### Storage

NXRM-HA supports various blob store backends for artifact storage:

- **S3** - AWS S3 buckets (recommended for production)
- **Azure Blob Storage** - Azure blob containers
- **NFS** - Network File System v4
- **AWS EFS** - Elastic File System
- **File** - Local filesystem via PVC (development only)

For production deployments, use external blob storage (S3/Azure) for shared artifact storage across replicas.

### Database

NXRM-HA requires PostgreSQL for database storage:

```yaml
addons:
  nxrm-ha:
    values:
      # Internal PostgreSQL (default - development only)
      postgresql:
        install: true

      # OR External PostgreSQL (recommended for production)
      postgresql:
        install: false
      nexus:
        database:
          host: "your-db-host.rds.amazonaws.com"
          user: "nexus"
          password: "your-password"
```

**Database Requirements:**
- PostgreSQL 12+ (16.9 recommended)
- Database with `pg_trgm` extension enabled
- Sufficient max_connections (350 recommended for HA setups)

### Istio Configuration

Istio interaction with NXRM-HA will be automatically toggled dependent on whether you have enabled Istio.

When enabled, an Istio VirtualService will be deployed, along with other configuration for NXRM-HA's interaction in the service mesh.

## Monitoring

Monitoring interaction with NXRM-HA will be automatically toggled dependent on whether you have enabled monitoring.

When enabled, a ServiceMonitor is deployed for automatic scraping of exposed metrics by Prometheus.

## Resiliency and High Availability

NXRM-HA supports High Availability configurations with Nexus Repository Manager Pro:

| Mode | Replicas | Requirements |
|------|----------|--------------|
| OSS (Default) | 1 | PostgreSQL |
| Pro HA | 3+ | Pro License, External PostgreSQL, External Blob Storage (S3/Azure) |

### HA Configuration Example

```yaml
addons:
  nxrm-ha:
    values:
      postgresql:
        install: false
      nexus:
        database:
          host: "your-ha-postgres.rds.amazonaws.com"
          user: "nexus"
          password: "your-password"
        blobstores:
          enabled: true
          blobstore:
            - name: "production-s3"
              type: "s3"
              blobstore_data:
                bucketConfiguration:
                  bucket:
                    name: "your-nexus-artifacts"
                    region: "us-east-1"
      upstream:
        statefulset:
          replicaCount: 3
          clustered: true
          container:
            env:
              install4jAddVmParams: "-Xms2703m -Xmx2703m -Dnexus.datastore.nexus.maximumPoolSize=80"
        secret:
          license:
            licenseSecret:
              enabled: true
              fileContentsBase64: "<your-base64-encoded-license>"
```

## Single Sign On (SSO)

SSO can be configured for NXRM-HA by following the instructions from the package documentation [here](https://repo1.dso.mil/big-bang/product/packages/nxrm-ha/-/blob/main/docs/keycloak.md).

## Pro License Configuration

By default, Big Bang will deploy the OSS (unlicensed) version of Nexus. If you need Pro features such as HA or advanced security, you can add your license via values:

```yaml
addons:
  nxrm-ha:
    values:
      upstream:
        secret:
          license:
            licenseSecret:
              enabled: true
              fileContentsBase64: "<your-base64-encoded-license>"
```

Encode your license file:
```bash
base64 -w 0 nexus-repo-license.lic
```

NOTE: This should be added via encrypted values to protect the license.

## Values Structure

NXRM-HA uses a **passthrough pattern** for configuration:

- **Big Bang additions** (hostname, domain, istio, monitoring, sso, nexus.database, etc.) stay at the root level
- **Upstream Sonatype chart values** are nested under the `upstream:` key

```yaml
addons:
  nxrm-ha:
    values:
      # Big Bang additions (root level)
      hostname: nexus
      domain: bigbang.dev
      istio:
        enabled: true
      networkPolicies:
        enabled: true
      nexus:
        database:
          host: "postgres.example.com"
          user: "nexus"
          password: "your-password"

      # Upstream chart values (nested under 'upstream')
      upstream:
        statefulset:
          replicaCount: 1
          container:
            image:
              repository: registry1.dso.mil/ironbank/sonatype/nexus/nexus
              nexusTag: 3.84.0-03
            resources:
              requests:
                cpu: "4"
                memory: "4Gi"
```

## Migration from Legacy Chart

If you are migrating from the legacy `nexus-repository-manager` chart, see the migration guides:

| Guide | Use Case | Estimated Downtime |
|-------|----------|-------------------|
| [OSS Migration Guide](https://repo1.dso.mil/big-bang/product/packages/nxrm-ha/-/blob/main/docs/migration-oss.md) | OSS/Development with embedded H2 database | 30-60 minutes |
| [Pro Migration Guide](https://repo1.dso.mil/big-bang/product/packages/nxrm-ha/-/blob/main/docs/migration-pro.md) | Pro/Production with external PostgreSQL | 30-45 minutes |

### Key Differences from Legacy Chart

| Feature | Legacy Chart | NXRM-HA |
|---------|-------------|---------|
| Values Key | `addons.nexusRepositoryManager` | `addons.nxrm-ha` |
| Workload Type | Deployment | StatefulSet |
| Database | H2 (embedded) or external | PostgreSQL required |
| Values Pattern | Direct values | Upstream passthrough (`upstream:` key) |
| High Availability | Not supported | Supported (Pro license required) |
| Namespace | nexus-repository-manager | nxrm-ha |

## Health Checks

NXRM provides two endpoints to monitor health status:

- `http://<hostname>:<port>/service/rest/v1/status` - Verifies that a node can handle read requests
- `http://<hostname>:<port>/service/rest/v1/status/writable` - Verifies that a node can handle read and write requests

Success is represented as `HTTP 200 OK`, failure as `HTTP 503 SERVICE UNAVAILABLE`.

## Additional Documentation

- [NXRM-HA General Documentation](https://repo1.dso.mil/big-bang/product/packages/nxrm-ha/-/blob/main/docs/general.md)
- [SSO/Keycloak Integration](https://repo1.dso.mil/big-bang/product/packages/nxrm-ha/-/blob/main/docs/keycloak.md)
- [Prometheus Integration](https://repo1.dso.mil/big-bang/product/packages/nxrm-ha/-/blob/main/docs/PROMETHEUS.md)
- [Network Policies](https://repo1.dso.mil/big-bang/product/packages/nxrm-ha/-/blob/main/docs/networkPolicies.md)
- [Sonatype Documentation](https://help.sonatype.com/repomanager3)
