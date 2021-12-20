# Policy Naming Convention

Policy files and resources should be named according to the nomenclature below so that an intuitive connection be made between the functionality, configuration files, resources, and testing.

The following items should be named the same:

- `chart/templates/<name>.yaml`
  - `<ClusterPolicy>.metadata.name: <name>`
- `tests/manifests/<name>.yaml`
  - `<TestResource>.metadata.name: <name>-#`

## Validate Policies

Validate policy names should start with one of the following:

- `disallow-`: for policies that prevent a setting
- `require-`: for policies that require a specific setting
- `restrict-`: for policies that only allow a setting based on a whitelist

## Generate Policies

Generate policy names should start with one of the following:

- `clone-`: for policies that clone existing resources
- `create-`: for policies that create new resources

## Mutate Policies

Mutate policy names should start with one of the following:

- `add-`: for policies that add missing settings
- `remove-`: for policies that remove existing settings
- `replace-` for policies that modify or replace a setting

## Special Policies

CVE related policies should be named after the CVE unique identifier:

- `cve-xxxx-xxxxx.yaml`
