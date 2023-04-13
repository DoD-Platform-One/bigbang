# General Conventions Style Guide
This style guide outlines the general conventions to follow for package names, structure standardization, version numbers, and YAML formatting focusing on the Big Bang Helm chart. Individual packages (core, addons, community) may not follow these exact standards.

## Package Names
When creating package names, consider that different usages of the name will require different formats. For Helm values keys use camelCase to delineate multi-word package names. Avoid using . or - within values keys to simplify Helm templating. Kubernetes resources require translation to kebab-case as they do not support uppercase. Package naming for Kubernetes resources should be consistent across all resources (GitRepository, Namespace, HelmRelease, labels, etc).

##### Notable Exceptions
> If a package name is two words and the additional words are less than four characters, consider it as part of the single name. Examples include "fluentbit" (technically "Fluent Bit") and "argocd" (technically "Argo CD").

> The "log storage" packages are deployed to the `logging` namespace rather than their respective names (`elasticsearch-kibana` and `loki`). This was primarily done to accommodate persistence of data for legacy deployments.

## Formatting YAML
When formatting YAML files, follow these guidelines:

- Indent using two spaces, not tabs.
- Use camelCase and alphanumeric keys, without any special characters.
- Ensure that all Kubernetes resource names, repository names, and namespaces are lowercase, alphanumeric, or hyphenated, using kebab-case.

## Structure Standardization
For each package, ensure that the following items have the same name:

- Folder: chart/templates/<package\>
- Top-level key: chart/templates/values.yaml
- Namespace: chart/templates/<package\>/namespace.yaml, unless targeting another package's namespace.
- Repo name: https://repo1.dso.mil/bigbang/packages/<package\>


##

Consistency is key when it comes to formatting choices. Ensure that your changes to Big Bang follow these formatting guidelines consistently throughout.

Remember that these conventions are meant to serve as a starting point, and it's always important to consider the specific needs and constraints of your contribution when making decisions about package names, structure, versioning, and formatting.
