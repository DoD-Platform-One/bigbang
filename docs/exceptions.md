# Kyverno Policy Exception Guide

If you have a violation of a Kyverno policy, one of the following actions can be taken to remedy the situation.  The actions are listed from most-preferred to least preferred.

## Fix the resource problem

Whenever possible, attempt to fix the problem in the resource that is causing the violation.  This eliminates the risk and provides the highest security posture.

> If you cannot fix the problem, you must discuss your exception plan with your security team to insure the risk is acceptable for your cluster.

## Add a specific exclusion

Each policy has an `exclude` key that can be used to add exceptions to the policy.  Review [Kyverno's exclude documentation](https://kyverno.io/docs/writing-policies/match-exclude/) for details.  It is recommended that your exclusion be as specific as possible.

> Kyverno expands pod policies automatically to pod controllers (i.e. Deployments, Daemonsets, StatefulSets, Jobs, CronJobs).  Exclusions for pods must account for the names of the pod controllers as well.

Here is an example of how to exclude pods named `bar-*` in namespace `foo` from a policy:

```yaml
policies:
  somePolicy:
    exclude:
      any:
      # Add a justification here for why the exclusion is needed
      - resources:
          # Do NOT include `kind` so the exclusion will work on pod controllers too
          namespaces:
          - foo
          names:
          # Use bar* instead of bar-* to capture pod controllers or pod names
          - bar*
```

**Risk**: Matching resource names in this namespace now have the ability to violate this policy.

## Exclude a namespace

In some cases, you may need to apply a policy only on specific namespaces.  This type of exclusion usually applies to features that you only have enabled but don't apply to some namespaces (e.g. istio sidecar injection).  To exclude by namespace, use the `exclude` key and only include the namespace:

```yaml
policies:
  somePolicy:
    exclude:
      any:
      # Add a justification here for why the exclusion is needed
      - resources:
          namespaces:
          - foo
```

**Risk**: Any resources in the namespace now have the ability to violate this policy.

## Only include specific namespaces

In some cases, you may want to only apply a policy to a specified list of namespaces.  For example, you want to insure [Guaranteed Quality of Service](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/) on high priority namespaces.  To do this, you would use the `match` key to add the namespace.  The following adds the policy to the `foo` and `bar` namespaces only:

```yaml
policies:
  somePolicy:
    match:
      any:
      - resources:
          namespaces:
          - foo
          - bar
```

> There are other options that can be used to `match` resources like kind, labels, etc.  See [Kyverno's match documentation](https://kyverno.io/docs/writing-policies/match-exclude/) for details.

**Risk**: All resources outside of the specified namespace(s) have the ability to violate the policy.

## Add or remove an allowance to the policy

Some policies have a list of allowed, disallowed, or required values that can be expanded or reduced to change the scope of the policy.  For example, you may want to add an additional registry to the allowed registries policy. You will need to look at the `parameters` section for the policy to see what is available.  Below is an example of adding an allowance:

```yaml
policies:
  somePolicy:
    parameters:
      allow:
      # Enter a comment for justifying the new set of values
      - safevalue
```

> If you only need an allowance added for a subset of the cluster, it may be  better to create a duplicate policy with a different set of allowances and use match/exclude settings to apply it to each namespace.

**Risk**: All resources, cluster wide, will be able to use the value specified as allowed.

## Disable the policy

As a last resort, policies can be disabled using the `enabled` flag, like the following:

```yaml
policies:
  somePolicy:
    # Enter a comment to justify why the policy is not needed
    enabled: false
```
