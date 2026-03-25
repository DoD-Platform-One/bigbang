# Integration: Overview

The following documents should be followed, in order, to move a package to maintained or (\*) fully integrate a new package into Big Bang:

For package deprecation and downward/high-impact track changes, use the [Package Offboarding Checklist](../package-offboarding/index.md).

- [ ] 1. [Complete Track Change Governance](https://repo1.dso.mil/big-bang/product/bbtoc/-/blob/master/process/Package%20Maintenance%20Tracks.md): Follow the Package Maintenance Tracks governance process (BBTOC issue, Big Bang value stream review, Jedi/Big Rocks review as needed, communications planning, and Cyber review approvals), set external status to `in process`, and document the final decision in ADR/BBTOC records.
- [ ] 2. Confirm Sponsor (Integrated only): Packages entering or remaining Big Bang Integrated require an explicit stakeholder sponsor recorded in BBTOC and ADR updates.
- [ ] 3. [Upstream Helm Chart](upstream.md): Initialize package workspace using an upstream Helm chart
- [ ] 4. [CICD Pipeline](pipeline.md): Establish a baseline package pipeline for testing changes
- [ ] 5. [\*Flux Helm Chart](flux.md): Create Flux compatible GitOps Helm chart required by Big Bang
- [ ] 6. [Big Bang Common Library](bb-common.md): Integrate with bb-common for service mesh, network policies, and Istio hardening
- [ ] 7. [Monitoring](monitoring.md): Enable metrics scraping on product
- [ ] 8. [Database](database.md): If required, add internal and external database support using Big Bang values
- [ ] 9. [Object Storage](storage.md): If required, add internal or external object storage support using Big Bang values
- [ ] 10. [Single-Sign On](sso.md): If available, add Single-Sign On (SSO) through internal or external identify provider
- [ ] 11. [Additional Tests](testing.md): Add testing to validate basic functionality
- [ ] 12. [Policy Enforcement](policy-enforcement.md): Update package to comply with default security and governance policies in Big Bang
- [ ] 13. Cyber Review: Complete Cyber security review and address any findings required by the governance process.
- [ ] 14. [Supported Package](supported.md): Migrate package into the Big Bang repo as an integrated or maintained package
- [ ] 15. [Final Documentation](documentation.md): Add additional Big Bang documentation for final release
- [ ] 16. Development: Add any subdomains exposed by the package to [the k3d-dev script](https://repo1.dso.mil/big-bang/bigbang/-/blob/master/docs/reference/scripts/developer/k3d-dev.sh?ref_type=heads#L24).
- [ ] 17. [\*Big Bang Merge Request](bigbang-merge-request.md): Create Big Bang Merge Request and run all packages pipeline
