# Package Lifecycle: Integration

Use this technical checklist to integrate a package with Big Bang.

- [ ] 1. [Upstream Helm Chart](../package-integration/upstream.md): Initialize package workspace using an upstream Helm chart.
- [ ] 2. [CICD Pipeline](../package-integration/pipeline.md): Establish a baseline package pipeline for testing changes.
- [ ] 3. [Flux Helm Chart](../package-integration/flux.md): Create a Flux-compatible GitOps Helm chart required by Big Bang.
- [ ] 4. [Big Bang Common Library](../package-integration/bb-common.md): Integrate with bb-common for service mesh, network policies, and Istio hardening.
- [ ] 5. [Monitoring](../package-integration/monitoring.md): Enable metrics scraping on product.
- [ ] 6. [Database](../package-integration/database.md): If required, add internal and external database support using Big Bang values.
- [ ] 7. [Object Storage](../package-integration/storage.md): If required, add internal or external object storage support using Big Bang values.
- [ ] 8. [Single-Sign On](../package-integration/sso.md): If available, add SSO through internal or external identity provider.
- [ ] 9. [Additional Tests](../package-integration/testing.md): Add testing to validate basic functionality.
- [ ] 10. [Policy Enforcement](../package-integration/policy-enforcement.md): Update package to comply with default security and governance policies in Big Bang.
- [ ] 11. [Supported Package](../package-integration/supported.md): Migrate package into the Big Bang repo as an integrated or maintained package.
- [ ] 12. [Final Documentation](../package-integration/documentation.md): Add Big Bang documentation for final release.
- [ ] 13. [Big Bang Merge Request](../package-integration/bigbang-merge-request.md): Create the Big Bang MR and run all packages pipeline.

For non-technical process gates, see [Onboarding](onboarding.md).
