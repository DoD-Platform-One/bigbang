# Headlamp

## Overview

Headlamp is an optional Kubernetes web interface. Big Bang integrates its package with the platform ingress, identity, policy, and monitoring capabilities.

## Big Bang Integration

Configure the package under `packages.headlamp` when using `packageConfiguration.version: v1`. For Big Bang 3.x configurations that have not enabled the unified package contract, the legacy path is `addons.headlamp`.

The integration:

- Deploys Headlamp into the `headlamp` namespace.
- Exposes the application through the selected Big Bang Istio gateway.
- Supports optional OIDC SSO and creates the required client Secret when credentials are supplied.
- Applies common Big Bang network-policy, authorization-policy, monitoring, and test settings.

Headlamp is disabled by default. Review its RBAC configuration before enabling it because the permissions granted to Headlamp determine what authenticated users can view or change in the cluster.

Use the generated [Values Reference](../../configuration/base-config.md) for the exact Big Bang configuration contract. Use the [Headlamp package repository](https://repo1.dso.mil/big-bang/product/packages/headlamp) for packaged chart values, implementation details, and its changelog.
