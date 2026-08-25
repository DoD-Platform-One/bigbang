# BBCTL

## Overview

BBCTL provides Big Bang operational and policy dashboards. The umbrella chart deploys the package only when both BBCTL and the monitoring stack are enabled.

## Big Bang Integration

Configure the package under `packages.bbctl` when using `packageConfiguration.version: v1`. For Big Bang 3.x configurations that have not enabled the unified package contract, the legacy path is `bbctl`.

The integration:

- Deploys the package into the `bbctl` namespace.
- Connects BBCTL dashboards to the Big Bang monitoring, Grafana, Alloy, and Loki stack.
- Passes repository credentials, registry overrides, and the preflight-check image from the Big Bang configuration.
- Applies common Big Bang network-policy, authorization-policy, and test settings.

Use the generated [Values Reference](../../configuration/base-config.md) for the exact Big Bang configuration contract. Use the [BBCTL package repository](https://repo1.dso.mil/big-bang/product/packages/bbctl) for packaged chart values, implementation details, and its changelog.
