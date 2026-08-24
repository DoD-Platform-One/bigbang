# Production Considerations

[[_TOC_]]

This section describes production-oriented configuration considerations for selected Big Bang package integrations. It is not a complete production baseline. Production readiness also depends on the cluster platform, capacity, availability requirements, identity architecture, storage, networking, security controls, backup strategy, and operational processes for the environment.

## Package Guides

| Package  | Primary considerations                                                                | Guide                   |
| -------- | ------------------------------------------------------------------------------------- | ----------------------- |
| GitLab   | External PostgreSQL, Redis or Valkey, object storage, Rails secrets, and capacity     | [GitLab](gitlab.md)     |
| Vault    | Initialization, auto-unseal, TLS, high availability, persistent storage, and recovery | [Vault](vault.md)       |
| Keycloak | External PostgreSQL, TLS, administrator credentials, availability, and capacity       | [Keycloak](keycloak.md) |

## Shared Checklist

For every production package:

- Use the package version selected by the Big Bang release and review its upgrade notes before changing versions.
- Keep desired state in an environment repository and protect credentials and private keys with SOPS or another approved secret-management workflow.
- Replace development credentials, initialization automation, bundled stateful dependencies, and permissive network ranges where the package guide identifies them.
- Define availability, capacity, persistence, retention, and recovery requirements before selecting replica and resource values.
- Render the complete ordered values set, review the resulting resources and Secrets, and test reconciliation before promotion.
- Exercise backup and restore procedures, not only backup creation.
- Monitor application health, dependencies, certificate expiry, storage capacity, and reconciliation status.

## Documentation Boundaries

These guides explain how Big Bang values configure each integration. The package repositories remain authoritative for component-specific settings, supported versions, migrations, and detailed operating procedures. General backup and recovery guidance belongs under [Operations](../../operations/), and version transitions belong under [Migration](../../migration/).

Values under `addons.<package>.values` pass through to the corresponding package chart. Consult the selected package version's chart values and documentation before adding passthrough values.
