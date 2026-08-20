# Big Bang Documentation

Big Bang is an umbrella Helm chart that uses Flux to deploy and reconcile a configurable collection of Kubernetes packages.

## Start Here

New to Big Bang? Follow the [Getting Started](getting-started/) path:

1. Understand [what Big Bang manages](getting-started/#what-is-big-bang) and what remains outside its boundary.
2. Review the [prerequisites](getting-started/prerequisites.md) for your selected release and configuration.
3. Choose an installation path:
   - [Evaluation quickstart](getting-started/quick-start.md) for a disposable development or demonstration cluster.
   - [First production-oriented deployment](getting-started/first-deployment.md) for a customer-managed GitOps environment.
   - [Disconnected deployment](installation/environments/airgap.md) when dependencies must be mirrored inside the environment.
4. Continue with [configuration](configuration/) and [operations](operations/) before promoting a deployment to production.

The evaluation quickstart is not a production baseline. Big Bang also does not provision or harden the Kubernetes cluster on which it runs.

## Find Documentation by Task

| Goal | Documentation |
| --- | --- |
| Understand the architecture and GitOps model | [Concepts](concepts/) |
| Configure global and package values | [Configuration](configuration/) |
| Choose an environment-specific deployment pattern | [Installation](installation/) |
| Operate, upgrade, and troubleshoot a deployment | [Operations](operations/) |
| Review integrated and optional packages | [Packages](packages/) |
| Follow a focused procedure | [Tutorials](tutorials/) |
| Contribute to Big Bang or package development | [Community and Development](community/) |

## Sources of Truth

Documentation is versioned with the repository. When instructions disagree with generated or executable content for the selected release, use these sources in order:

1. [`chart/Chart.yaml`](../chart/Chart.yaml) for the chart and Kubernetes version constraints.
2. [`chart/values.yaml`](../chart/values.yaml) and the generated [configuration reference](configuration/base-config.md) for values and defaults.
3. [`base/`](../base) and rendered manifests for Flux resources and Kubernetes objects.
4. The selected release notes for required migrations and known changes.

## Get Help

- Search [troubleshooting](operations/troubleshooting/) for the failing layer or symptom.
- Review [Repo1 work items](https://repo1.dso.mil/big-bang/bigbang/-/work_items) before reporting a defect.
- Follow the repository [contributing guide](../CONTRIBUTING.md) when proposing a change.
