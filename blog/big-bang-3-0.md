# Big Bang 3.0 💥

The countdown is on! Big Bang 3.0 is on track for release on June 13, 2025. This marks the next major release since version 2.0 in April 2023, and the Big Bang team has been working diligently to deliver a platform that's secure, feature-rich, and ready for your most critical missions. The Big Bang universe is ever-expanding, read on to learn more!

## Changes

### ⚙️ Istio Goes Operatorless

Service mesh management receives a major upgrade in 3.0 with the **removal of the Istio Operator in favor of direct Helm-based Istio deployments**. The operator, initially implemented to address limitations of Helm v2, became obsolete with the release of Helm v3, prompting its [deprecation by the Istio Project last year](https://istio.io/latest/blog/2024/in-cluster-operator-deprecation-announcement/).

By migrating to direct Helm deployments, Big Bang adopts recommended practices for Istio management and improves its overall security posture through the removal of the high-privilege operator. This transition also offers a standardized and more secure method for managing Istio configurations, simplifying installation and upgrades, and paving the way for [Ambient Mode](https://istio.io/latest/docs/ambient/overview/) integration in future releases.

Be advised, **this is a breaking change**, but our engineers have worked hard to make the migration as straightforward as possible for our community. For step-by-step instructions and insights, please refer to our dedicated Operatorless Istio [blog post](https://docs-bigbang.dso.mil/latest/blog/bb-3-0-operatorless-istio-migration/) and our detailed [migration guide](https://repo1.dso.mil/big-bang/bigbang/-/blob/master/docs/guides/using-bigbang/migrating-istio-for-bb3.0.md). To ensure a seamless transition, users are strongly encouraged to begin the migration process now. Operatorless Istio reached General Availability in Big Bang versions 2.53 and 2.54.

### 🧰 Grafana Alloy Replaces Promtail

Keeping with the theme of deprecated packages, we’re also replacing our primary log collection agent, **Promtail**, with **Grafana Alloy**, following Grafana Labs' [deprecation of Promtail earlier this year](https://grafana.com/docs/loki/latest/release-notes/v3-4/#deprecations). Alloy brings several key improvements to Big Bang's telemetry collection, including greater efficiency, lower costs for Prometheus-compatible metrics, full OTLP compatibility, and native support for metrics, logs, traces, and profiles.

Much of this transition is already complete. Alloy-logging features were added to Big Bang in version 2.51, and the Alloy chart was moved into Core in 2.53. With Alloy enabled by default in 3.0 and Promtail disabled, we'll be removing Promtail entirely from Big Bang in release 3.5.0, after which the package will move to Community-supported.

Users with custom Promtail configurations will need to convert and test their setups with Alloy before release 3.5.0. To assist with this transition, please refer to [Grafana's migration guide](https://grafana.com/docs/alloy/latest/set-up/migrate/from-promtail/) for detailed instructions, and the [Big Bang ADR](https://repo1.dso.mil/big-bang/bigbang/-/blob/7fa70f7b4cc4ca66c20ac28b74f19c265eaa798a/docs/adrs/0004-alloy-replacing-promtail.md) for general information about this change.  

### 🛡️ Flux Drift Detection By Default

With Big Bang 3.0, **drift detection** will be enabled by default on our **Flux `HelmRelease` resources**, resulting in a strengthened security posture and better adherence to the principles of defense in depth.

This feature will prevent unwanted deviations between the desired and actual cluster state, ensuring that any unauthorized changes made through the Kubernetes API will be automatically reverted during Flux's reconciliation process. With drift detection enabled, Flux will actively monitor for discrepancies between the intended configuration and the current state of the cluster. If a drift is detected, changes will be automatically reverted for more efficient operation.

While drift detection will be enabled by default for most existing HelmReleases, a few newer packages, such as Backstage or the charts that comprise Operatorless Istio, will have it implemented in subsequent releases. For more information about this upcoming change, [click here](https://repo1.dso.mil/big-bang/bigbang/-/blob/7fa70f7b4cc4ca66c20ac28b74f19c265eaa798a/docs/adrs/0005-drift-detection.md)!

### 💡 The Universe Expands: Headlamp, Backstage, and Compliance Dashboard

To further enhance Big Bang’s value as a comprehensive platform for building, deploying, and managing secure and compliant Kubernetes applications, our 3.0 release broadens its capabilities with the addition of three new packages to the umbrella chart:  

- **[Headlamp](https://repo1.dso.mil/big-bang/product/packages/headlamp)** – A user-friendly Kubernetes UI, specifically recommended by the Flux maintainers for monitoring Flux Custom Resource state without requiring `kubectl` or similar tools.
  - [Big Bang Docs: Headlamp](https://docs-bigbang.dso.mil/latest/packages/headlamp/)
  - [headlamp.dev](https://headlamp.dev/)
- **[Backstage](https://repo1.dso.mil/big-bang/product/packages/backstage)** – An open-source framework for building developer portals with additional customized modules for integrating with many of the applications in Big Bang. It’s already popular among the Big Bang community for providing self-service portals.
  - [Big Bang Docs: Backstage](https://docs-bigbang.dso.mil/latest/packages/backstage/)
  - [backstage.io](https://backstage.io/)
- **[Compliance Dashboard](https://repo1.dso.mil/big-bang/apps/sandbox/compliance-dashboard)** – A unified dashboard for reviewing cluster security policies and overall compliance, helping SREs address the challenge of parsing disparate security data sources by aggregating data from multiple security tools into one easy-to-read UI and assigning clusters an overall Compliance Score.

### ⚡️ Streamlining Updates with the Passthrough Pattern

This release introduces a new values pattern to some of our packages that we're calling the "Passthrough Pattern." While primarily an under-the-hood improvement, this change streamlines the delivery of package updates to our users.

The Big Bang team will continue maintaining Big Bang packages, but without forking upstream project helm charts. If it is necessary modify a package's helm templates, we either contribute upstream or make the modification with mutating webhooks or post renderers. This change greatly reduces the workload of our routine package renovate process.

You may have already seen this pattern in a few packages, like Kiali, Backstage, and Operatorless Istio, with many more adopting it in 3.0. Watch the Upgrade Notices in the Release Notes for instructions on how to update your deployments as we roll out this change.

### 💨 Quickstart Templates are Even Quicker

Big Bang 3.0 accelerates onboarding with revamped customer templates and a streamlined quickstart guide, complete with an automated deployment script for faster setup. We've also improved documentation around best practices for production configuration, making it easier to configure your cluster for optimal performance.

## 💬 Get In Touch

We're excited to bring you Big Bang 3.0 and hope you find these improvements valuable. If you have any questions or need assistance, our team is here to help!

- [Register to attend our next briefing](https://www.zoomgov.com/meeting/register/Q-2KHrmZStaCSsdafKsr2w#/registration), scheduled for Thursday 5 June 2025 at 1300 CT
- Join the Big Bang Distro List for the latest Big Bang BBTOC, Immersion Series, and e-mail updates
  - *send a request to `aflcmc.hncx.platformonebigbang@us.af.mil` to be added to the distro*
- [Join the Big Bang Slack Channel](https://join.slack.com/t/bigbanguniver-ft39451/shared_invite/zt-36e17n71f-w1hALTP5OH6wkkX7Eo2G~Q)

We also extend a sincere thank you to everyone who participated in the Istio beta program, and to all our community members submitting contributions, bug reports, and feature requests. Your feedback is invaluable to the work that we do. So, as always, *thank you for helping us build a better Big Bang!* 🚀
