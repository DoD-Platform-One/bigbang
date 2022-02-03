# Big Bang Package: Flux Integration

Big Bang uses a continuous deployment tool, [Flux](https://fluxcd.io/) to deploy packages using Helm charts sourced from Git ([GitOps](https://www.weave.works/technologies/gitops/)).  This document will cover how to integrate a Helm chart, from a mission application or other package, into the Flux pattern required by Big Bang.  Once complete, you will be able to deploy your package with Big Bang.

## Prerequisites

- [Helm](https://helm.sh/docs/intro/install/)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- A multi-node Kubernetes cluster to deploy Big Bang and your package
- A [Big Bang project containing the upstream Helm chart](./package-integration-upstream.md)

> Throughout this document, we will be setting up an application called `podinfo` as a demonstration

## Big Bang Helm Chart

The purpose of the Big Bang Helm chart is to create a Big Bang compatible, easy-to-use spec for deploying the package. Reasonable and safe defaults are provided and any needed secrets are auto-created. We accept the trade-off of easy deployment for complicated template code. Details are in the following steps.

   ```shell
   gitrepository.yaml    # Flux GitRepository, configured by Big Bang chart values.
   helmrelease.yaml      # Flux HelmRelease, configured by Big Bang chart values.
   namespace.yaml        # Namespace creation and configuration
   imagepullsecret.yaml  # Secret creation for image pull credentials
   values.yaml           # Big Bang customization of the package and passthrough values.
   ```

Create a new Helm chart for Big Bang resources in the root of your Git repository:

```shell
# short name of the package
export PKGNAME=podinfo

# version of the package in semver format
export PKGVER=6.0.0

# Make directory structure
mkdir -p bigbang/templates/$PKGNAME

# Create values file
touch bigbang/values.yaml

# Copy helpers from Big Bang
curl -sL -o bigbang/templates/_helpers.tpl https://repo1.dso.mil/platform-one/big-bang/bigbang/-/raw/master/chart/templates/_helpers.tpl

# Create chart file
cat << EOF >> bigbang/Chart.yaml
apiVersion: v2
name: bigbang-$PKGNAME
description: BigBang compatible Helm chart for $PKGNAME
type: application
version: 0.1.0
appVersion: "$PKGVER"
EOF
```

### Namespace

The package will be deployed in its own namespace.  BigBang pre-creates this namespace so that labels and annotations can be controlled.  Setup `bigbang/templates/$PKGNAME/namespace.yaml` with the following:

```yaml
{{- $pkg := "podinfo" }}
{{- if (get .Values $pkg).enabled }}
apiVersion: v1
kind: Namespace
metadata:
  name: {{ $pkg }}
  labels:
    app.kubernetes.io/name: {{ $pkg }}
    {{- include "commonLabels" . | nindent 4}}
{{- end }}
```

In order for the namespace Helm template to be properly created, the following values need to be added to `bigbang/values.yaml`:

```yaml
# Identifies if our package should be deployed or ignored
podinfo:
  enabled: true
```

### Flux Custom Resources

#### GitRepository

Flux's source controller uses the [GitRepository](https://fluxcd.io/docs/components/source/gitrepositories/) resource to pull Helm chart changes from Git.  Use the [GitRepository API Specification](https://fluxcd.io/docs/components/source/gitrepositories/#specification) to create a `GitRepository` resource named `bigbang/templates/$PKGNAME/gitrepository.yaml` with the following content:

```yaml
{{- $pkg := "podinfo" }}
{{- if (get .Values $pkg).enabled }}
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: GitRepository
metadata:
  name: {{ $pkg }}
  namespace: {{ .Release.Namespace }}
  labels:
    app.kubernetes.io/name: {{ $pkg }}
    {{- include "commonLabels" . | nindent 4}}
spec:
  interval: {{ .Values.flux.interval }}
  url: {{ (get .Values $pkg).git.repo }}
  ref:
    {{- include "validRef" (get .Values $pkg).git | nindent 4 }}
  {{ include "gitIgnore" . }}
  {{- include "gitCreds" . | nindent 2 }}
{{- end }}
```

The `GitRepository` Helm template above requires the following values to be added to `bigbang/values.yaml`:

```yaml
podinfo:
  # The Git location of the package Helm chart
  git:
    repo: https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/podinfo
    branch: master
```

> If you are working on a branch, change `master` to the branch you are working from in the values above.

#### HelmRelease

Big Bang exclusively uses Helm charts for deployment through Flux.  Using the [HelmRelease API Specification](https://fluxcd.io/docs/components/helm/helmreleases/#specification), create a `HelmRelease` resource named `bigbang/templates/$PKGNAME/helmrelease.yaml` with the following content:

```yaml
{{- $pkg := "podinfo" }}
{{- $fluxSettings := merge (get .Values $pkg).flux .Values.flux -}}
{{- if (get .Values $pkg).enabled }}
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: {{ $pkg }}
  namespace: {{ .Release.Namespace }}
  labels:
    app.kubernetes.io/name: {{ $pkg }}
    {{- include "commonLabels" . | nindent 4}}
spec:
  targetNamespace: {{ $pkg }}
  chart:
    spec:
      chart: {{ (get .Values $pkg).git.path }}
      interval: 5m
      sourceRef:
        kind: GitRepository
        name: {{ $pkg }}
        namespace: {{ .Release.Namespace }}

  {{- toYaml $fluxSettings | nindent 2 }}

  {{- if (get .Values $pkg).postRenderers }}
  postRenderers:
  {{ toYaml (get .Values $pkg).postRenderers | nindent 4 }}
  {{- end }}
  valuesFrom:
    - name: {{ .Release.Name }}-{{ $pkg }}-values
      kind: Secret
      valuesKey: "common"
    - name: {{ .Release.Name }}-{{ $pkg }}-values
      kind: Secret
      valuesKey: "defaults"
    - name: {{ .Release.Name }}-{{ $pkg }}-values
      kind: Secret
      valuesKey: "overlays"
{{- end }}
```

The following values need to be added into `bigbang/values.yaml` for `HelmRelease`:

```yaml
podinfo:
  # Directory in git where Helm chart is located
  git:
    path: chart
  # Flux specific settings for package
  flux: {}
```

### ImagePullSecret

Big Bang images are pulled from Iron Bank.  In order to provide credentials for Iron Bank, Big Bang will create a secret for each package called `private-registry`.  In `bigbang/templates/$PKGNAME/imagepullsecret.yaml`, add the following content:

```yaml
{{- $pkg := "podinfo" }}
{{- if (get .Values $pkg).enabled }}
{{- if ( include "imagePullSecret" . ) }}
apiVersion: v1
kind: Secret
metadata:
  name: private-registry
  namespace: {{ $pkg }}
  labels:
    app.kubernetes.io/name: {{ $pkg }}
    {{- include "commonLabels" . | nindent 4}}
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: {{ template "imagePullSecret" . }}
{{- end }}
{{- end }}
```

> Other secrets can be added for credentials, certificates, etc. by creating a file named `bigbang/templates/$PKGNAME/secret-<name>.yaml`.  Big Bang is responsible for creating these secrets using values from the user.  More details are included in the integration documentation for databases, object stores, sso, etc.

### Package Values

Package values (chart/values.yaml) should contain upstream values plus any placeholders of values needed for Big Bang.The following guidelines should be used when adding values to the package:

- Assume the package will be run without Big Bang.  Values enabling features from other packages (e.g. metrics, ingress, SSO) should be turned off by default.  Big Bang will enable them through overrides.
- Re-use existing chart values rather than adding new ones when possible.
- Only change the default values from the upstream Helm chart when necessary.
- Comment any changes made to the upstream Helm values so it is clear that the changes should carry forward on upgrades.
- Assume that Big Bang will create secrets (e.g. TLS certificates, credentials) and provide the reference to the chart.
- Create blank placeholders for Big Bang values to avoid Helm errors during deployment.

### Override Values

Big Bang has a few options for overwriting values in packages.  The package's `HelmRelease`, that we created earlier, contains a `ValuesFrom` section that references a secret with `common`, `default`, and `overlay` keys.  Each of these keys can contain a set of override values that get passed down to the package.  Here is a table explaining the difference between the possible overlays:

|Name|Description|Source|Priority|
|--|--|--|--|
| `overlay` | Values provided by user when deploying Big Bang | `bigbang/values.yaml`:`$PKGNAME.values.*` | Highest 1 |
| `default` | Values created by Big Bang | `bigbang/templates/$PKGNAME/values.yaml`:`*` | 2 |
| `common` | Big Bang values common to all packages | Not currently used | 3 |
| `package` | Package defaults | `chart/values.yaml`:`*` | Lowest 4 |

This means that if a user provides a value for the package, that overwrites the value Big Bang or the package would create.

For the package to implement this hierarchy, `bigbang/templates/$PKGNAME/values.yaml` must be created with the following:

```yaml
{{- $pkg := "podinfo" }}
{{- define "bigbang.defaults.podinfo" -}}

{{- end }}

{{- /* Create secret */ -}}
{{- if (get .Values $pkg).enabled }}
{{- include "values-secret" (dict "root" $ "package" (get .Values $pkg) "name" $pkg "defaults" (include (printf "bigbang.defaults.%s" $pkg) .)) }}
{{- end }}
```

### Check Syntax

At this point, you should have a minimum viable set of values in `bigbang/values.yaml` that looks like this:

```yaml
podinfo:
  enabled: true
  git:
    repo: https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/podinfo
    branch: bigbang
    path: chart
  flux: {}
```

Use the Big Bang default values to make sure our Helm templates don't have any syntax errors.  Run the following:

   ```shell
   # Get the helm chart
   git clone https://repo1.dso.mil/platform-one/big-bang/bigbang ~/bigbang

   # Check that our chart generates without errors
   # We want our local values to override the big bang defaults, so we need to specify both
   helm template -n bigbang -f ~/bigbang/chart/values.yaml -f bigbang/values.yaml bigbang-podinfo bigbang
   ```

### Validation

To validate that the Helm chart is working, perform the following steps to deploy your package.  This assumes you already have a Kubernetes cluster running.

1. Disable all default packages in Big Bang by adding the following to `bigbang/values.yaml`

   ```yaml
   # Network Policies
   networkPolicies:
     enabled: false

   # Istio
   istiooperator:
     enabled: false
   istio:
     enabled: false

   # Gatekeeper
   gatekeeper:
     enabled: false
   clusterAuditor:
     enabled: false

   # Logging
   eckoperator:
     enabled: false
   logging:
     enabled: false
   fluentbit:
     enabled: false

   # Monitoring
   monitoring:
     enabled: false

   # Other Tools
   jaeger:
     enabled: false
   kiali:
     enabled: false
   twistlock:
     enabled: false
   ```

1. Install flux using the [instructions from Big Bang](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/1.19.0/docs/guides/deployment_scenarios/quickstart.md#step-8-install-flux).
1. Install the package using the bigbang Helm chart

   ```shell
   helm upgrade -i -n bigbang --create-namespace -f ~/bigbang/chart/values.yaml -f bigbang/values.yaml bigbang-podinfo bigbang
   ```

1. Watch the `GitRepository`, `HelmRelease`, and `Pods`:

   ```shell
   watch kubectl get gitrepo,hr,po -A
   ```

1. Troubleshoot any errors

   ```shell
   kubectl get events -A
   ```

   > If you are using a private Git repository or pulling images from a private image repository, you will need to add credentials into the `git.credentials.username`/`git.credentials.password` and/or `registryCredentials.username`/`registryCredentials.password` using the `--set` option for Helm.

1. Cleanup cluster

   ```shell
   helm delete -n bigbang bigbang-podinfo
   ```

1. Add the following to `bigbang/README.md` to document this Helm charts usage:

   ```markdown
   # Big Bang compatible Helm chart

   This helm chart deploys the application using the same methods and values as Big Bang.

   ## Prerequisites

   - Kubernetes cluster matching [Big Bang's Prerequisites](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/tree/master/docs/guides/prerequisites)
   - [FluxCD](https://fluxcd.io/) running in the cluster
   - The [Big Bang git repository](https://repo1.dso.mil/platform-one/big-bang/bigbang) cloned into `~/bigbang`
   - [Helm](https://helm.sh/docs/intro/install/)

   ## Usage

   ### Installation

   1. Install Big Bang
   `helm upgrade -i -n bigbang --create-namespace -f ~/bigbang/chart/values.yaml -f bigbang/values.yaml bigbang ~/bigbang/chart`
   1. Install this chart
   `helm upgrade -i -n bigbang --create-namespace -f ~/bigbang/chart/values.yaml -f bigbang/values.yaml bigbang-podinfo bigbang`

   ### Removal

   `helm delete -n bigbang bigbang-podinfo`

   ```

1. Commit your changes

   > If you are developing something different than `podinfo`, run `grep -ir podinfo` to make sure your replaced all of the instances with your application name.

   ```shell
   git add -A
   git commit -m "feat: added bigbang helm chart"
   git push
   ```
