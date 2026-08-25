# Thanos

## Overview

Thanos is an optional extension to the Big Bang monitoring stack for querying and retaining Prometheus metrics across longer time periods or multiple environments.

## Big Bang Integration

Configure the package under `packages.thanos` when using `packageConfiguration.version: v1`. For Big Bang 3.x configurations that have not enabled the unified package contract, the legacy path is `addons.thanos`.

The integration:

- Connects the monitoring package's Prometheus sidecar to Thanos.
- Adds Thanos as a Grafana data source.
- Supports an external S3-compatible object store or package-managed MinIO configuration.
- Supports optional SSO and exposure through the selected Big Bang Istio gateway.
- Applies common Big Bang network-policy, authorization-policy, monitoring, and test settings.

Thanos is disabled by default. Plan object-store availability, retention, credentials, encryption, capacity, and recovery before using it for production metrics retention. Store access credentials in encrypted secret values.

Use the generated [Values Reference](../../configuration/base-config.md) for the exact Big Bang configuration contract. Use the [Thanos package repository](https://repo1.dso.mil/big-bang/product/packages/thanos) for packaged chart values, implementation details, and its changelog.
