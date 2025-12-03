# Nexus Repository Manager

> **DEPRECATION NOTICE**: The `nexus-repository-manager` package is deprecated and will be removed in a future Big Bang release. Please migrate to the new [`nxrm-ha`](./nxrm-ha.md) package. See the [Migration Guides](#migration-to-nxrm-ha) section below for details.

## Overview

Nexus repository manager is used to store build artifacts and provide features to push and pull artifacts using integration tools. Nexus provides a wealth of documentation [here](https://help.sonatype.com/repomanager3) with details about supported artifact formats, use cases, and more.

## Big Bang Touch Points

The below diagram includes the main Big Bang touchpoints to Nexus as well as a basic workflow for using Nexus.

```mermaid
graph LR
  subgraph "Workflow"
    sourcecontrol("Source Control") --> build("Build") --> repository1("Repository") --> release("Release")
  end

  subgraph "Nexus Repository Manager"
    nexusrepositorymanager("Nexus Repository Manager") --> repository1("Repository")
  end

  subgraph "Environment"
    release("Release") --> stage1(dev)
    release("Release") --> stage2(staging)
    release("Release") --> stage3(prod)
  end

  subgraph "Monitoring" 
    prometheus("Prometheus") --> servicemonitor("Service Monitor")
    servicemonitor("Service Monitor") --> nexusrepositorymanager("Nexus Repository Manager")
  end

  subgraph "Logging"
    nexusrepositorymanager("Nexus Repository Manager") --> fluent(Fluentbit) --> logging-ek-es-http
    logging-ek-es-http{{Elastic Service<br />logging-ek-es-http}} --> elastic[(Elastic Storage)]
  end
```

### UI

Nexus Repository Manager serves as the user interface for Nexus. Nexus Repository Manager provides optional anonymous access for users who need to search repositories, browse repositories and look through the system feeds. UI access is exposed through the Istio Virtual Service.

### Logging

You can configure the level of logging for the repository manager and all plugins as well as inspect the current log using the user interface.
Logging can be enabled by clicking on the Logging menu item in the Administration submenu in the main menu. Logs are auto-scraped and shipped via your chosen logging stack when deployed with bigbang.

### Storage

Nexus requires access to persistent storage for storing repos, docker registries, etc. Persistent storage values can be set/modified in the bigbang chart:

```yaml
addons:
  nexusRepositoryManager:
    values:  
      persistence:
        storageSize: 8Gi
        accessMode: ReadWriteOnce
```

### Istio Configuration

Istio interaction with Nexus will be automatically toggled dependent on whether you have enabled Istio.

When enabled an Istio VirtualService will be deployed, along with other configuration for Nexus' interaction in the service mesh.

## Monitoring

Monitoring interaction with Nexus will be automatically toggled dependent on whether you have enabled monitoring.

When enabled a servicemonitor is deployed for automatic scraping of exposed metrics by prometheus.

## Resiliency

Nexus provides a helpful upstream guide on resiliency and high availability [here](https://help.sonatype.com/repomanager3/planning-your-implementation/resiliency-and-high-availability). Nexus does not support a traditional HA setup (more than 1 replica) so backups for resiliency are recommended.

## Single Sign on (SSO)

SSO can be configured for Nexus by the following the instructions from the package documentation [here](https://repo1.dso.mil/big-bang/product/packages/nexus/-/blob/main/docs/keycloak.md)

## Licensing

By default, Big Bang will deploy the unlicensed version of Nexus. If you need some of the license features, such as SSO, you can add your license via values and it will be added to the deployment:

```yaml
addons:
  nexusRepositoryManager:
    enabled: true
    license_key: |
      ehjgjhh...
```

NOTE: This should be added via encrypted values to protect the license.

### Health Checks

Nexus Repository Manager uses Repository Health Check (RHC) for health checking. Repository Health Check (RHC) allows Nexus Repository users to identify open source security risks in proxy repositories at the earliest stages of their DevOps pipeline by providing the following key capabilities:

- A summary of components with security vulnerabilities categorized by severity.
- A count of license warnings per component categorized by severity.

## Migration to NXRM-HA

The legacy `nexus-repository-manager` chart is being replaced by the new `nxrm-ha` chart, which provides:

- **High Availability Support**: Deploy Nexus Repository Manager Pro in a highly available, multi-node configuration
- **Production-Ready Architecture**: Built-in support for external databases (PostgreSQL, AWS RDS) and object storage (S3, Azure Blob)
- **Active Maintenance**: Official Sonatype-supported Helm chart with direct updates
- **Improved Configuration**: Upstream passthrough pattern for cleaner values structure

### Migration Guides

Choose the appropriate migration guide based on your deployment:

| Guide | Use Case | Estimated Downtime |
|-------|----------|-------------------|
| [OSS Migration Guide](https://repo1.dso.mil/big-bang/product/packages/nxrm-ha/-/blob/main/docs/migration-oss.md) | OSS/Development with embedded H2 database | 30-60 minutes |
| [Pro Migration Guide](https://repo1.dso.mil/big-bang/product/packages/nxrm-ha/-/blob/main/docs/migration-pro.md) | Pro/Production with external PostgreSQL | 30-45 minutes |

### Key Differences

| Feature | Legacy Chart | NXRM-HA |
|---------|-------------|---------|
| Values Key | `addons.nexusRepositoryManager` | `addons.nxrm-ha` |
| Workload Type | Deployment | StatefulSet |
| Database | H2 (embedded) or external | PostgreSQL required |
| Values Pattern | Direct values | Upstream passthrough (`upstream:` key) |
| High Availability | Not supported | Supported (Pro license required) |
| Namespace | nexus-repository-manager | nxrm-ha |

For detailed migration instructions and values mapping, see the [NXRM-HA General Documentation](https://repo1.dso.mil/big-bang/product/packages/nxrm-ha/-/blob/main/docs/general.md).
