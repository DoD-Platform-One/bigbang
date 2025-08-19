# Streamlining Integration with [`bb-common`](https://repo1.dso.mil/big-bang/product/packages/bb-common)

## Setting the stage

Big Bang has always aimed to deliver a secure, ready-to-use Kubernetes platform
for the Department of Defense. But as the ecosystem has grown and new packages
have been added, one area has become a constant source of friction: **network
policies**.

Until now, each Big Bang package tended to define its own policies in slightly
different ways. The result? Inconsistency, duplication, and confusion — both for
contributors and for engineers trying to consume Big Bang downstream.

## The Problem with Inconsistency

- Different packages often modeled the same types of rules in different formats.
- Some components shipped with overly permissive defaults, while others were
  locked down in unexpected ways.
- Updates or fixes to a common rule meant repeating the same changes across
  multiple charts.
- Network policies were not flexible enough to accommodate all the varied use
  cases our users needed.

In short, we had a patchwork approach to network security — and that doesn't
scale when you’re trying to deliver a coherent, secure-by-default platform.

## Our solution: `bb-common`

To fix this host of issues, we've introduced a new **hybrid library chart**,
[`bb-common`](https://repo1.dso.mil/big-bang/product/packages/bb-common),
designed specifically at the start to handle network policy creation across all
Big Bang components, with support for more features to follow.

Instead of each package rolling its own rules, they can now rely on a **single
shared implementation**:

- **Consistency:** Common patterns (like allowing monitoring traffic or
  inter-namespace communication) are implemented once and reused everywhere.
- **Security:** Default-deny policies are enforced uniformly, with clear,
  predictable overrides.
- **Maintainability:** Fixes and improvements only need to be made in one place.
- **Testability:** `bb-common` has a comprehensive test suite to ensure policies
  are generated correctly.
- **Flexibility:** A domain-specific language (DSL) allows for expressing
  complex rules in a concise, human-readable way.

## What this means for users of Big Bang

For downstream Big Bang consumers, `bb-common` means:

- Fewer surprises — policies will look and behave the same across all
  components.
- More confidence — you can trust that security boundaries are enforced the same
  way, no matter which packages you deploy.
- More control — advanced users can take advantage of our domain-specific
  language to express complex rules with more universally understood semantics.
- Auditability — policies are defined directly in the package's `values.yaml`,
  making it easier to review and understand the effective rules at a glance.

### Some examples

These examples come from the
[`bb-common` `NetworkPolicy` documentation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/network-policies/README.md?ref_type=heads).
You're encouraged to check out the full documentation for more details and
examples.

#### Basic pod-to-pod communication

**Original NetworkPolicy:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: frontend
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: backend
          podSelector:
            matchLabels:
              app.kubernetes.io/name: api
      ports:
        - port: 8080
          protocol: TCP
```

**Migrated to bb-common:**

```yaml
networkPolicies:
  enabled: true
  egress:
    from:
      frontend:
        to:
          k8s:
            backend/api:8080: true
```

#### Multiple pods and ports

**Original NetworkPolicy:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-egress-policy
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: api
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: database
          podSelector:
            matchLabels:
              app.kubernetes.io/name: postgres
      ports:
        - port: 5432
          protocol: TCP
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: cache
          podSelector:
            matchLabels:
              app.kubernetes.io/name: redis
      ports:
        - port: 6379
          protocol: TCP
    - to:
        - ipBlock:
            cidr: 52.84.0.0/16
      ports:
        - port: 443
          protocol: TCP
        - port: 8443
          protocol: TCP
```

**Migrated to bb-common:**

```yaml
networkPolicies:
  enabled: true
  egress:
    from:
      api:
        to:
          k8s:
            database/postgres:5432: true
            cache/redis:6379: true
          cidr:
            52.84.0.0/16:[443,8443]: true
```

#### Complex ingress rules

**Original NetworkPolicy:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-ingress-policy
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: api
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: frontend
          podSelector:
            matchLabels:
              app.kubernetes.io/name: web
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: admin
      ports:
        - port: 8080
          protocol: TCP
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: monitoring
          podSelector:
            matchLabels:
              app.kubernetes.io/name: prometheus
      ports:
        - port: 9090
          protocol: TCP
```

**Migrated to bb-common:**

```yaml
networkPolicies:
  enabled: true
  ingress:
    to:
      api:8080:
        from:
          k8s:
            frontend/web: true
            admin/*: true # Any pod from admin namespace
      api:9090:
        from:
          k8s:
            monitoring/prometheus: true
```

## `bb-common`, hybrid library charts, and the passthrough pattern

### Hybrid library charts

For `bb-common`, we wanted to be flexible with how it could be integrated into a
package, so we designed it as a **hybrid library chart**. This means:

- It can be used as
  [a traditional library chart](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/network-policies/README.md?ref_type=heads#using-bb-common-as-a-library-chart),
  providing templates that our packages can include and use as needed.
- It can also be used as a standalone chart or
  [subchart](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/network-policies/README.md?ref_type=heads#using-bb-common-as-a-subchart),
  allowing packages to deploy it directly if they want to leverage its full
  capabilities without needing to include individual templates.

### Passthrough pattern

One of the bigger architectural shifts Big Bang has undergone in the past year
has been the move to a **passthrough pattern** for our package integrations,
eliminating forking upstream charts and instead overriding them to suit the
needs of Big Bang.

With this shift, we've unified on a single key for the upstream package's
overrides, `upstream`, and kept the top-level keys for Big Bang-specific
overrides as needed on a per-package basis.

### How does `bb-common` fit in?

`bb-common` is being integrated into key packages at this stage as a library
chart, with each package selectively including only the templates it needs.

In the future, however, the goal is to convert these packages to using
`bb-common` as a subchart, aliased under a single `bigbang` key at the top level
to signal more clearly to the user what parts of the configuration are being
managed by Big Bang versus the upstream package.

## Timelines

The initial rollout of `bb-common` has begun with key packages like `kiali` and
`monitoring`, which have already been updated to use the new framework for their
network policies.

We're going to slow-walk this rollout to not overwhelm our users with too many
changes too often. Over the next few months, we're prioritizing understanding
the impact of these changes, gathering feedback, and iterating on the design as
needed.

Once we're confident in the stability and usability of `bb-common` for network
policies, we'll begin iterating on other concerns like Istio's CRDs and slowly
rolling those out to the same packages. Again, the goal is to ensure a smooth
transition for our users. **We do not want to rush this process.**

Once we're comfortable with the stability of `bb-common` and its adoption across
key packages, we'll look to make it a standard part of the Big Bang platform,
encouraging all packages to leverage it for their network policies and other
cross-cutting concerns.

When we have a more concrete timeline for this broader adoption, we'll share it
with the community.

## Looking Forward

This is just the first step. By consolidating network policy logic into
`bb-common`, we've set the stage for:

- Easier adoption of new security requirements.
- Faster iteration on best practices.
- A more stable, predictable Big Bang for everyone building on top of it.

Once we've ironed out any kinks we might encounter with network policies, we
plan to extend `bb-common` to handle other cross-cutting concerns, like
`AuthorizationPolicies`, `ServiceEntries`, `VirtualServices`, and more.

---

## Call to action

If you’re a Big Bang consumer or contributor, we encourage you to:

- Explore the
  [`bb-common` documentation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/README.md?ref_type=heads).
- Try out the new network policy framework in the packages where `bb-common` is
  already in use, like `kiali` and `monitoring`.
- [Provide feedback](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/issues/new)
  — we want to make this as seamless and powerful as possible.
