# Frequently Asked Questions

Use this page to understand what Big Bang provides, deploy and configure it, keep it upgraded, and find the right help.

## Find the Right Starting Point

| Your goal | Start here |
| --- | --- |
| Understand whether Big Bang fits your program | [Overview](index.md), [Architecture](concepts/architecture.md), and the [Big Bang Universe](https://universe.bigbang.dso.mil/) |
| Prepare a deployment | [Prerequisites](getting-started/prerequisites.md) |
| Deploy a mission application | [Extra Package Deployment](installation/environments/extra-package-deployment.md) |
| Upgrade an existing deployment | [Upgrades](operations/upgrades.md) |
| Report a defect or request a feature | [Big Bang work items](https://repo1.dso.mil/big-bang/bigbang/-/work_items) |

## Understand Big Bang

> What does Big Bang provide, and when should my program use it?

Big Bang provides a configurable Kubernetes platform baseline that integrates packages for GitOps, networking, policy enforcement, observability, and security. Because packages share coordinated versions, updating one value can update a whole suite of applications at once, reducing the work of integrating and patching each piece separately. Some teams find Big Bang's opinionated defaults get in the way of specific customizations and deploy upstream charts directly instead — both are valid, but going upstream means you take on the integration, security configuration, and upgrade coordination Big Bang otherwise handles.

Big Bang does not provide the underlying cluster, automatically grant an authorization to operate, or run the environment for you. Your organization remains responsible for infrastructure, application deployment, security controls, upgrades, and ongoing operations. See [Overview](index.md), [Architecture](concepts/architecture.md), and [Security Model](concepts/security-model.md) to evaluate fit.

> Why deploy Big Bang packages instead of deploying upstream Helm charts sourced directly from GitHub?
 
A chart sourced directly from GitHub or a public repository hasn't been through Big Bang's hardening or integration process — you're responsible for vetting the chart, sourcing compliant images instead of Iron Bank's pre-scanned ones, and wiring in your own service-mesh, policy, and secrets configuration from scratch. Big Bang packages come with that baseline already applied, and their versions are tested together as a coordinated set.
 
The trade-off is flexibility: Big Bang is opinionated about how packages are wired together, so some teams deploy upstream charts directly when they need a specific version, feature, or configuration Big Bang doesn't yet support. You can do either, or mix both — using Big Bang for your core platform and upstream charts for anything outside it — but going upstream means taking on the integration, image vetting, and security configuration Big Bang otherwise handles.

## Getting Started

> Does using Big Bang cost anything or require a contract?

No. Big Bang is open-source and free to use — no cost, contract, or permission needed from Platform One. You control which components you install, though your Approving Official may require certain commercial applications for a cATO. See the [Licensing Model](concepts/licensing.md) for details.

Platform One also offers optional paid services if you want them: the Big Bang Integration Team (install/upgrade/operate support), Digital Twin (tests baseline changes against your app), and [Party Bus](https://p1.dso.mil/partybus) (a fully managed environment — no cluster to operate). [Contact us](https://p1.dso.mil/contact-us) for details, or share feedback through our [Feedback Form](https://forms.osi.apps.mil/r/QjGsAfZLeV).

## Security

> Does using Big Bang make my environment secure or compliant?

Big Bang provides configurable integrations for GitOps, policy enforcement, service mesh, observability, and runtime security, but it does not automatically make a system secure or grant an authorization to operate. The system owner remains responsible for infrastructure hardening, package selection, configuration, identity, vulnerability management, and control evidence — review the [Security Model](concepts/security-model.md) with your security team and Approving Official.

Most package images come from [Iron Bank](https://p1.dso.mil/ironbank), but you still need to verify every image your specific configuration renders — scan results don't replace your own vulnerability-management process.

## Deploying and Configuring

> Where can Big Bang run?

Big Bang can run on supported Kubernetes environments in public or government clouds, on-premises, and disconnected environments — but it requires a conformant Kubernetes cluster and can't be installed directly on a standalone VM. If your organization can't support a full Kubernetes environment, consider [Party Bus](https://p1.dso.mil/partybus) (Platform One's managed PaaS) instead.

Compatibility depends on the Big Bang release and your cluster's networking, storage, DNS, load-balancing, and registry capabilities — don't assume support based on the provider name alone. See [Prerequisites](getting-started/prerequisites.md) and test in a representative non-production environment first.

> Can I deploy an application that isn't already a Big Bang package?

Yes. You can deploy a mission application through Big Bang's `packages` configuration without first making it an official Big Bang package — the optional Wrapper chart adds common integrations (Istio, monitoring, network policies, secrets, limited SSO) automatically. You remain responsible for the application's chart, images, configuration, security, and testing. See [Extra Package Deployment](installation/environments/extra-package-deployment.md).

If you'd like the package to become part of the officially supported Big Bang catalog instead, follow the [package lifecycle onboarding](community/development/package-lifecycle/onboarding.md) and [integration](community/development/package-lifecycle/integration.md) guides.

> Can I validate or dry-run my configuration before deployment?

Yes — use `helm template` and `kustomize build` to render and review your config locally. But no local command fully proves it'll work in your cluster: test in a staging environment that mirrors production, since CRDs, admission policies, and other runtime dependencies can only be validated against a real cluster. See [Configuration](configuration/index.md).

> Can I use cloud-native authentication or an external secret store?

Depending on your environment and selected packages, you may be able to use cloud-native registry authentication instead of a static image pull secret — for example, some configurations support ambient pull access via an AWS EKS node IAM role. You can also use the optional External Secrets Operator package with providers such as AWS Secrets Manager or Vault instead of storing every secret with SOPS. Support and exact configuration vary by provider, registry, package, and release and can change between versions — confirm current behavior for your release before relying on it, and open an [issue](https://repo1.dso.mil/big-bang/bigbang/-/work_items) if something doesn't work as documented. See [External Secrets Operator](packages/addons/external-secrets-operator.md).

## Upgrades and Change Control

> How often is Big Bang released, and how should I prepare for an upgrade?

Big Bang generally follows a two-week release cadence. You don't have to deploy every release immediately, but review the release notes and upgrade notices for each intervening release so you don't miss a breaking change or required migration step.

Before upgrading production, review the changelogs for every package you use, test the upgrade and rollback in a staging environment, and verify Flux, Helm releases, and your applications afterward. Major changes such as an Istio migration have their own dedicated guides — see the [release notes](https://repo1.dso.mil/big-bang/bigbang/-/releases), [Upgrade guide](operations/upgrades.md), and [Migration guides](migration/index.md).

## Getting Help

> Where can I get help, report a bug, or contribute a fix?

Search [Big Bang work items](https://repo1.dso.mil/big-bang/bigbang/-/work_items) first. If it's not already reported, open one with your Big Bang version, Kubernetes version, affected packages, and reproduction steps — never include credentials or sensitive configuration. To contribute a fix, link your merge request to the work item and follow the [Contributing guide](../CONTRIBUTING.md).

Community channels don't include a dedicated point of contact or guaranteed response time for every program. If you need hands-on or contractual support, [contact Platform One](https://p1.dso.mil/contact-us) directly.