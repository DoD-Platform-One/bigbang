---
revision_date: Last edited December 09, 2024
tags:
  - blog
---

# Big Bang Release 2.41.0: A Milestone in Enterprise Platform Development

We are thrilled to announce the release of Big Bang 2.41.0, marking another significant step forward in our enterprise platform development journey. This incremental release brings substantial improvements to stability, security, and core functionality across our component ecosystem.

## Release Highlights

The latest release includes comprehensive updates to critical components including GitLab, Istio, Kiali, and Kyverno. Our development teams have worked diligently to ensure these updates enhance both performance and security while maintaining seamless integration within the Big Bang ecosystem.

## Release Notes
We always encourage consumers to view the [Release notes](https://repo1.dso.mil/big-bang/bigbang/-/releases/2.41.0) for additional information.

## Team Achievements and Progress

### Storage and Collaboration Enhancements

- Comprehensive updates to Minio, Vault, Confluence, and External Secrets
- Implementation of ESO cluster secret functionality to allow for centralized secret management, dynamic secret injection, and cloud native integration. 

### Security and Compliance Advancement

- Completed renovate updates for Anchore Enterprise and Neuvector
- Internal testing of KubeScape project
- Refined Kyverno policy implementation
- Progress toward multi-cluster Twistlock deployment support

### Observability Improvements

- Successfully implemented Prometheus remote-write metrics to Mimir over Istio
- Completed updates to core monitoring tools including Loki, Grafana, and Fluentbit
- Advanced CI tracing tools integration with Alloy, Tempo, and Loki

### Service Mesh Developments

- Resolution of Tetrate image enabling in Sandbox Istio Gateway
- Advanced templating for public and passthrough gateway implementation
- Near completion of the Kiali labeling epic with only 13 remaining issues

### Repo Sync

- Updates and improvements to the Repo Sync utility which enables us to receive and accept community contributions [Further information on the current status can be found within the epic ](https://repo1.dso.mil/groups/big-bang/-/epics/400)

### Edge Computing Innovation

- Advancement of initiatives toward the anticipated 1.0 release

## Community Engagement

We extend our gratitude to Daniel Dides and the entire Big Bang team for their valued contributions to this release. The success of Big Bang relies heavily on the engagement of our community, and we request feedback through the following methods:
- [Issue](https://repo1.dso.mil/big-bang/bigbang/-/issues/new) reporting on our platform
- Consulting our [comprehensive documentation](https://docs-bigbang.dso.mil/latest/) for implementation guidance
- Providing [feedback](https://join.slack.com/t/bigbanguniver-ft39451/shared_invite/zt-2mrtefxg6-5WJr85JD3NPbreMuAcQR0A) on new features and improvements

## Looking Forward

As we continue to evolve Big Bang, our focus remains on delivering robust, secure, and scalable solutions for enterprise deployment. The progress demonstrated in this release reflects our commitment to excellence and continuous improvement across all aspects of the platform.

For detailed information about the upgrade process and known issues, please consult the release notes in our documentation. We look forward to your feedback and continued collaboration in making Big Bang even better.

*Stay tuned for more updates as we continue to enhance and expand the capabilities of Big Bang.*
