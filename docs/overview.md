# Kyverno Policies

Kyverno policies were pulled from the [Kyverno Policy Library](https://kyverno.io/policies) and converted to a Helm template for flexibility.  Policy descriptions can be found in [policies.md](./policies.md).

If you are transitioning from OPA Gatekeeper to Kyverno policies, see the [Gatekeeper vs. Kyverno Policy Comparison](./gatekeeper.md) for assistance.

## Features

Each policy has the following features:

### Annotations

- `policies.kyverno.io/title`: name of the policy
- `policies.kyverno.io/category`: policy catigory (e.g. security, best practice)
- `policies.kyverno.io/severity`: the seriousness that should be taken for violations of this policy.  Values will be `critical`, `high`, `medium`, `low`.
- `policies.kyverno.io/subject`: the Kubernetes resource(s) targeted by the policy (e.g. `Pod`)
- `policies.kyverno.io/description`: a full description of the what the policy does and why it is important

### Overrides

Each policy takes into account global overrides and policy specific overrides for configuration.  See the [README.md](../README.md) and [values.yaml](../chart/values.yaml) for what attributes can be overridden.

If you need to create a policy exception, see the [Exception Guide](exceptions.md).

### Parameters

Some policies have had values parameterized to make it more flexible.  These values will be listed under `parameters`.

## Additional Policies

Custom policies can be created by adding them to the `additionalPolicies` key as a map.  See the `samplePolicy` in [values.yaml](../chart/values.yaml) for instructions on how to add policies.
