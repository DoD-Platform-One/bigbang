# Policy Naming Convention

Policy files and resources should be named according to the nomenclature below so that an intuitive connection be made between the functionality, configuration files, resources, and testing.

The following items should be named the same:

- ClusterPolicy:
  - `chart/templates/<name>.yaml`
    - `.metadata.name: <name>`
- Test Resource:
  - `chart/tests/manifests/<name>.yaml`
    - `.metadata.name: <name>-#`

## Validate Policies

Validate policy names should start with one of the following:

- `disallow-`: policies that permit resources if a setting is undefined or does **not** match the disallowed list
- `require-`: policies that permit resources if a setting is defined and matches the required list
- `restrict-`: policies that permit resources if a setting is undefined or matches the allowed list.

When possible, limitations should be parameterized in `values.yaml` under `parameters`.  To make it easier to remember, use the following names for parameters:

- `disallow-*` policies should use `disallow: []` to indicate values that will not be allowed
- `require-*` policies should use `require: []` to indicate values that will be required
- `restrict-*` policies should use `allow: []` to indicate values that will be allowed

## Generate Policies

Generate policy names should start with one of the following:

- `clone-`: for policies that clone existing resources
- `create-`: for policies that create new resources

When possible, objects generated should be parameterized in `values.yaml` under `parameters`.  To make it easier to remember, use the following names for parameters:

- `clone-*` policies should use `clone: []` where each entry can contain fields matching the resource being cloned.  For example, `kind`, `name`, and `namespace` for a cloned `ConfigMap`.

## Mutate Policies

Mutate policy names should start with one of the following:

- `update-`: policies that adds or updates a setting

When possible, the values that the policy is updating from and to should be parameterized.  Use the following names for the parameters:

- `update-*` policies should use `update: []` where each entry contains:
  - `from`: indicates what to replace.  If blank, defaults to matching all values.
  - `to`: indicates what the new value should be.

## Special Policies

Vulnerability related policies should contain the reference to the CVE in the policy annotations.
