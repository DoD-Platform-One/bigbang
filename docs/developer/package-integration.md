# Big Bang Integration: Overview

The following documents should be followed, in order, to fully integrate a new package into Big Bang:

1. [Upstream Helm Chart](./package-integration-upstream.md): Initialize package workspace using an upstream Helm chart
1. [CICD Pipeline](./package-integration-pipeline.md): Establish a baseline package pipeline for testing changes
1. [Flux Helm Chart](./package-integration-flux.md): Create Flux compatible GitOps Helm chart required by Big Bang
1. [Service mesh](./package-integration-service-mesh.md): Integrate with service mesh for ingress/egress
1. [Monitoring](./package-integration-monitoring.md): Enable metrics scraping on product
1. [Database](./package-integration-database.md): If required, add internal and external database support using Big Bang values
1. [Object Storage](./package-integration-storage.md): If required, add internal or external object storage support using Big Bang values
1. [Single-sign On](./package-integration-sso.md): If available, add single-sign on (SSO) through internal or external identify provider.
1. [Additional Tests](./package-integration-testing.md): Add testing to validate basic functionality
1. [Network Policies](./package-integration-network-policies.md): Add ingress/egress policies to restrict network traffic for security
1. [Policy Enforcement](./package-integration-policy-enforcement.md): Update package to comply with default security and governance policies in Big Bang
1. [Supported Package](./package-integration-supported.md): Migrate package into the Big Bang repo as a supported package
1. [Final Documentation](./package-integration-documentation.md): Add additional Big Bang documentation for final release
