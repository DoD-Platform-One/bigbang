# Kyverno Policies

Kyverno policies were pulled from the [Kyverno Policy Library](https://kyverno.io/policies) and converted to a Helm template for flexibility.  Each policy has the following features:

## Annotations

- `policies.kyverno.io/category`: descriptive metadata for categorizing the policy as a security feature, best practice, or other arbitrary label.
- `policies.kyverno.io/severity`: the seriousness that should be taken for violations of this policy.  Values should be `critical`, `high`, `medium`, `low` or other values your organization uses.
- `policies.kyverno.io/subject`: the Kubernetes resource targeted by the policy (e.g. `pod`)
- `policies.kyverno.io/description`: a full description of the what the policy does and why it is important

## Overrides

Each policy takes into account global overrides and policy specific overrides for configuration.  See the [README.md](../README.md) for what attributes can be overridden.

## Parameters

Some policies have had values parameterized to make it more flexible.  These values will be listed under `parameters` and are stored in a `ConfigMap` for the policy to use at runtime.

## Additional Policies

Custom policies can be created by adding them to the `additionalPolicies` key as a map.  See the `samplePolicy` in [values.yaml](../chart/values.yaml) for instructions on how to add policies.
