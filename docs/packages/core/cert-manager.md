# cert-manager

cert-manager is an integrated Big Bang package that provisions the Kubernetes certificate management controller and its CRDs.

## Big Bang Touch Points

- The package is enabled with the top-level `certManager` values key.
- Workloads and CRDs are deployed into the `cert-manager` namespace.
- The cert-manager webhook receives Kubernetes API server admission callbacks. The package provides the required port-level Istio and NetworkPolicy handling for webhook port `10250`.
- The namespace is excluded from ambient enrollment by default; the package still supports ambient outbound handling and webhook bypass configuration.
- Prometheus metrics are exposed through a ServiceMonitor when monitoring is enabled.
- cert-manager installs and owns its CRDs. trust-manager and approver-policy are separate optional maintained packages that may share the namespace and consume cert-manager APIs.

## High Availability

The package uses the upstream controller, webhook, cainjector, and startup API check workloads. Big Bang defaults retain the package's configured replica and disruption settings; operators should review those values against their cluster's availability requirements.

## Storage and Credentials

cert-manager does not require a database, object storage, or built-in user authentication. Certificate material, issuer state, and ACME account keys are stored in Kubernetes Secrets. ACME account Secrets are sensitive identity data and must be backed up before disabling or uninstalling the package.

## Issuance and Routing

Self-signed and Let's Encrypt issuers are optional and disabled by default. Let's Encrypt DNS-01 and HTTP-01 configuration is environment-specific. HTTP-01 uses the operator-provided public FQDN and temporary solver resources; it does not create a fixed cert-manager subdomain for the Big Bang k3d development script.

## Related Documentation

- [Package overview](https://repo1.dso.mil/big-bang/product/packages/cert-manager/-/blob/main/docs/overview.md)
- [Installation notes](https://repo1.dso.mil/big-bang/product/packages/cert-manager/-/blob/main/docs/installing.md)
- [Let's Encrypt test plan](https://repo1.dso.mil/big-bang/product/packages/cert-manager/-/blob/main/docs/letsencrypt-test-plan.md)
