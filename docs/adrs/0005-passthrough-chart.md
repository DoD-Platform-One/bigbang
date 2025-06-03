# 5. Passthrough Package Helm Charts

Date: 2025-06-02

## Status

<unknown>

## Context

The Big Bang team is moving forward with using the passthrough helm chart pattern wherever possible. This pattern is intended to reduce the maintenance workload and complexity for renovating big bang packages. This new pattern for big bang packages will also reduce the reliance on an outdated and no longer support version of the [kpt](https://kpt.dev/) tool. This patten simply involves utilizing the upstream creator's chart as a helm dependency and layering the default values required to run the chart within the compliance standards of Big Bang.

## Decision

Creating a passthrough chart pattern is relatively simple. Declare a chart dependency in your Chart.yaml and pull tarfile into the chart. Please reference upstream [helm documentation](https://helm.sh/docs/topics/charts/#chart-dependencies) for specifics. Sample renovate config is listed below for automating the new helm dependency update.

In order to convert an existing `kpt` configured chart, the process is slightly more complicated. Remove all forked upstream template files, not Big Bang created template files, and `kptfile` while making note of any changes made to the upstream template files. Run the `helm dependency add <upstream dependent chart>` to add the chart as a dependency. Changes made to the template files can the be attempted to be made within the `values.yaml` file. For any changes that cannot be applied via `values.yaml`, a post renderer will need to be created in the Big Bang Repository. 

Sample Renovate config rule from:

```json
    {
      "customType": "regex",
      "description": "Update <chart> version>",
      "fileMatch": ["^chart/Chart\\.yaml$"],
      "matchStrings": ["version:\\s+(?<currentValue>.+)-bb\\.\\d+"],
      "depNameTemplate": "<chart-name>",
      "datasourceTemplate": "helm",
      "registryUrlTemplate": "<upstream helm repository>"
    }
```

Sample post-renderer config: 

```yaml
    {{- toYaml $fluxSettings<package> | nindent 2 }}
    {{- if or .Values.addons.<package>.postRenderers .Values.addons.<package>.postRenderersInternallyCreated}}
    postRenderers:
    {{- if .Values.addons.<package>.postRenderersInternallyCreated }}
    {{ include "<package>.postRenderersInternallyCreated" . | nindent 2 }}
    {{- end }}
    {{- with .Values.addons.<package>.postRenderers }}
    {{ toYaml . | nindent 2 }}
    {{- end }}
    {{- end }}
```

Big Bang internally created template files(e.g. `NetworkPolicy`s, `AuthorizationPolicy`s, etc.) will still be created under the `chart/templates/bigbang/` directory, with the aim being that commonly utilized template files will be consolidated into a repository within repo1.dso.mil for all packages to pull from in the future.

## Consequences 

Users will no longer be able to view the package values directly in the Big Bang package git repository. The `values.yaml` file will exist in a passthrough sub-chart tarfile bundle, which is still stored in the git repo, but not viewable from the GitLab console directly. The upstream GitHub repository for each sub-chart linked in the Big Bang chart's `README` can be used for viewing the `values.yaml` file and template files, however users should take care to ensure they are viewing the correct version of the files that is deployed via the passthrough sub-chart.

Another consequence of this passthrough chart pattern is that values settings will be abstracted one further layer than previously, requiring internal engineers and customers to modify their existing values overrides. Instead of previously where simply `.Values.<package-name>.<value-to-set>` was the way to access values on a package, now you will need to access it by also providing the package name, followed by an "upstream" alias, for example: `.Values.<package-name>.upstream.<value-to-set>`. 

While setting values in an override file, additional nesting is also required. An example for setting Tetrate's enterprise FIPS compliant image for Big Bang's implementation of [Istiod](https://repo1.dso.mil/big-bang/product/packages/istiod) (which follows this passthrough pattern) is provided below:

```yaml
# Package name
istiod:
  enabled: true
  # -- Values to passthrough to the istiod chart
  values:
    upstream:
      global:
        hub: registry1.dso.mil/ironbank/tetrate/istio

```