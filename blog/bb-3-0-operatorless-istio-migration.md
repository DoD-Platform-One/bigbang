# Big Bang 3.0 - Operatorless Istio Migration

It has been nearly two years since the Big Bang 2.0 release, and the project has
grown significantly in that time. The Big Bang engineering team is proud of the
product that we have built alongside our growing community. Your support and
feedback have been essential in shaping the platform your missions rely on.

In line with our mission-first principles, we want to share updates on the
direction of Big Bang and what it means for you as Big Bang operators.

## Istio operator deprecation

In August 2024, the Istio project
[announced](https://istio.io/latest/blog/2024/in-cluster-operator-deprecation-announcement/)
the deprecation of the Istio Operator in Istio 1.24. The Istio Operator was
created to address many of the problems with Helm 2. Helm 3 resolved many of
those issues. Additionally, the Istio project's data showed that less than 10%
of installations used the operator, with most relying on `istioctl` for initial
deployment and upgrades.

Big Bang prefers a declarative approach to package deployments. With Big Bang
3.0, we've extended that approach to installing Istio into Kubernetes clusters
without the operator or `istioctl`. We're doing this by leveraging the upstream
`base` and `istiod` charts in accordance with Istio's
[helm installation documentation](https://istio.io/latest/docs/setup/install/helm/#installation-steps).

Istio 1.23 has a
[generous EOL timeline](https://istio.io/latest/docs/releases/supported-releases/#support-status-of-istio-releases),
giving Big Bang engineers ample time to work through the migration. We've merged
initial packages to enable operatorless Istio.

These packages are currently in an **alpha** state and subject to change. Big
Bang consumers are **advised to avoid running these packages in production
environments**. However, if users want to test the new packages with their
custom configurations, they are available in Big Bang’s most recent release
under `istioCore`, `istioGatewayPublic`, and `istioGatewayPassthrough` at the
time of writing.

Because this new deployment paradigm is fundamentally incompatible with previous
Istio deployments in Big Bang, this transition is marked as a **breaking
change**. The Istio upstream project has set **May 2025** as the EOL point for
Istio 1.23 (including the Operator), so Big Bang is aiming for a **3.0
transition on or before that date**.

## Migration considerations

The Big Bang team is dedicated to making this transition as smooth as possible.
We are actively working on migration documentation and automation where
applicable.

Here are some key architectural changes you should be aware of:

### **Mesh operations**

✅ **No impact on existing mesh configurations**

- Your existing Istio CRs will continue to work **as-is** post-migration.
- `PeerAuthentication`, `ServiceEntry`, and `AuthorizationPolicy` remain
  unchanged.
- `istiod` continues to manage mesh operations—**the operator removal does not
  affect this**.

### **Gateways**

🚨 **Significant changes to Gateway deployments**

- Previously, `Gateway` configurations were embedded in `IstioOperator` CRs and
  managed by the operator.
- **In 3.0, Gateways must be installed via their own standalone Helm charts.**
- We are exposing the Istio gateway chart's API directly to Big Bang consumers
  rather than continuing with an abstraction layer.

✅ **Simplified Deployment with Iterable Helm Releases**

- We are developing an iterable `istioGateway` package to ease deployment.
- Users can still deploy custom `Gateway` resources manually, but our new
  package will reduce friction.
- More details on this feature will be shared in the coming weeks.

🔍 **Exploring Kubernetes-native Gateway API**

- We are researching the
  [K8s-native Gateway API](https://gateway-api.sigs.k8s.io/) as a potential
  primary ingress/egress configuration resource.
- This transition would increase flexibility and potentially support alternative
  service mesh implementations in the future.

### **Ambient mode**

We want to be clear that our transition to operatorless Istio is **not** a
transition to Istio’s ambient mode.

We think ambient Istio is promising and are researching how best to support it.
However, this migration **only focuses on removing the Istio Operator**. If and
when we have a clear path for ambient mode, we’ll share updates.

## Migration timeline

**Currently planned milestones for Big Bang 3.0:**

- **March 2025** – Operatorless Istio reaches beta status for broader testing.
- **April 2025** – Final testing phase for community feedback.
- **May 2025** – Big Bang 3.0 release, aligning with Istio 1.23 EOL.

## What you need to do

✅ **Test the new operatorless Istio packages in non-production environments.**

✅ **Review your Gateway configurations and prepare for standalone Helm-based
deployment.**

✅ **Keep an eye out for migration documentation and automation tools.**

✅ **Engage with the community to provide feedback or raise concerns.**

## Community thanks

As always, we want to thank our community for their continued support. We build
Big Bang for you, and our mission is to simplify and enable yours. If you have
any feedback or concerns, please share them in
[our community Slack](https://bigbanguniver-ft39451.slack.com/archives/C051A2BPS0K),
on Mattermost, or by
[making an issue](https://repo1.dso.mil/big-bang/bigbang/-/issues/new) in repo1.
