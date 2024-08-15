---
revision_date: Last edited April 13, 2023
tags:
  - blog
---

# Big Bang 2.0

What is Big Bang 2.0? Why are we doing it? 2.0 is the second major release since Big Bang 1.0 released in December 2020. This blog post should provide you with both the why behind what we're doing, as well as what the changes involved are, and what that means for you as a user.

## Why Change Things?

The majority of the why behind 2.0 comes down to customer pain points. A few of the top ones that tie into specific things changing in 2.0 are listed in the following:
1. The barrier to entry for users is too high, both from a technical/knowledge standpoint and from a cost perspective.
2. Upgrades of Big Bang are difficult, partially due to the large amount of changes in each release.
3. Adding on community packages/mission apps is too hard; there's no easy (or even documented) way to add a new community package to your deployment.

Beyond these pain points, there are also changes we are making to enable future platform improvements that necessitate a major release.

## What is Changing?

### Free and OpenSource Core by Default

The default core packages in 1.x releases come with both licensing and closed source concerns, as well as some usability concerns in some cases. Several of the default packages will be changing in 2.0 as a result. These changes are listed in the following:
* **Runtime Security:** NeuVector will replace Twistlock as the default. NeuVector is opensourced and does not come with a license cost.
* **Logging:** The Promtail/Loki/Grafana (PLG) stack will become the new default stack, replacing Elasticsearch/Fluentbit/Kibana (EFK). PLG has lower resource costs for users, and does not have a license requirement for core features.
* **Policy Enforcement:** Kyverno will replace Gatekeeper as the default. Kyverno provides a better user experience for policy writing, and is more directly focused on the Kubernetes experience.
* **Tracing:** Tempo will replace Jaeger as the default. Jaeger has a dependency on Elasticsearch for persistence, and Tempo is better integrated with the PLG stack to tie traces to specific logs.

These will be *small* breaking changes to user values. If you want to continue to deploy Twistlock, for example, you will need to adjust your values to disable NeuVector and enable Twistlock before upgrading. It's also important to note that we will continue to support the alternative packages in all of these cases, we do not intend to lock users in to a single option.

### Standardization of Naming

Within Big Bang, packages have a wide variety of naming conventions and mis-matches between different locations. Some packages may have a values key that doesn't match the namespace or `HelmRelease` name. In order to improve the user experience, we are standardizing the names in these areas. Package values keys will line up with the namespace and `HelmRelease`/`GitRepository` name 1:1 with case translations to accommodate different usages (`camelCase` for Helm values, `kebab-case` for Kubernetes resources). In addition, Big Bang will provide a documented style guide with any exceptions to the guide.

Once again - these will be *small* breaking changes to user values and potentially has effects on any extra user scripts/tooling on top of Big Bang. Exact changes will be provided as part of a follow on blog post and in the release notes for 2.0.

### Improved Package Extensibility

With 2.0 we will be providing a way to deploy community/arbitrary packages as part of Big Bang and as a "first-class" experience. This will provide a way for users to effectively extend Big Bang, and still have the lifecycle of additional packages tied to the Big Bang deployment directly. Beyond this, there will also be a new `wrapper` provided that offers some features for integration of an application inside of Big Bang, strictly via Big Bang values. This includes things like configuring `VirtualService`, `ServiceMonitor`, and `NetworkPolicy` resources.

For additional details on what this looks like from a user/values perspective, read the [extra package deployment guide](../docs/guides/deployment-scenarios/extra-package-deployment.md). This will be provided as a new feature, and not change any existing architecture/functionality.

### Upgrade Process Improvements

As mentioned in our "Why" section, upgrades for Big Bang are hard. A big piece of this is a lack of documentation surrounding what a Big Bang upgrade should look like, and how to complete one. In 2.0, we will be providing clear documentation around updates for both single packages and the entire stack as a whole.

One of the challenges we are balancing is keeping end users up to date with the latest security patches as quick as they release, while avoiding the danger of updating 10, 20, or 30+ packages in a single upgrade. Part of our approach to resolving this pain is releasing/encouraging smaller upgrades at a more frequent rate. A piece of our solution for this is providing the Renovate tool as a Big Bang package, along with providing guidance around usage and templates for configuration. Renovate is a tool that provides automation of dependency updates. Within the context of Big Bang, this would alert end users of new package releases and provide automatic changes to the user's GitOps config repo in the form of merge/pull requests. The ultimate goal is for customers to be able to update packages asynchronously from the Big Bang releases (i.e., smaller updates, more often).

This again will largely look more like a new feature, although it may have implications to the current release process/cadence. We will continue to release Big Bang versions, but again, we hope for these to be smaller updates due to package updates happening differently. As a result the requirements for a major/minor/patch version will be different and will be documented in the near future.

### OCI HelmRepositories

OCI `HelmRepository` will be offered as a deployment option instead of `GitRepository` in 2.0. Big Bang charts are currently being published as Helm OCI artifacts in `registry1.dso.mil/bigbang` and will be published for all Big Bang core, addon, and community packages. It is important to call out that there is no inherent extra scanning/security going into these artifacts today; this is largely just a "storage format" change for the way Flux sources the Helm charts. In the future, Big Bang will be signing our OCI Helm charts and providing for verification of these signatures by end users, increasing confidence in our supply chain security. We also hope this will enable future improvements to the airgap process. All artifacts needed for Big Bang will be "OCI shaped," both the images and the Helm charts.

This is a change in the underlying architecture of Big Bang, but it will be offered as an option in 2.0 to start with, and `GitRepository` will remain the default. We anticipate changing the default in the future but `GitRepository` will remain an option long-term to enable a variety of deployment needs.

## Where can I Learn More?

Big Bang's 2.0 epic is a great place to start [here](https://repo1.dso.mil/groups/big-bang/-/epics/217). Beyond this, we encourage users to get involved via the [BBTOC](https://repo1.dso.mil/platform-one/bbtoc).

Continue reading about Big Bang 2.0 in [part 2 of this series](./2-0-breaking-changes.md), which is focused specifically on the breaking changes included in 2.0.
