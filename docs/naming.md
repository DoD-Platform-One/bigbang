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

- `allow-`: policies that permit resources if a setting matches the allowed list or is undefined.
- `deny-`: policies that permit resources if a setting does **not** match the deny list or is undefined
- `require-`: policies that permit resources if a setting is defined and matches the required list

## Generate Policies

Generate policy names should start with one of the following:

- `clone-`: for policies that clone existing resources
- `create-`: for policies that create new resources

## Mutate Policies

Mutate policy names should start with one of the following:

- `update-`: policies that adds or updates a setting

## Special Policies

Vulnerability related policies should contain `cve` in the name, preferably as a suffix.
