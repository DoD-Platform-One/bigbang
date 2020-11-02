# Umbrella

Work in progress umbrella package

## Usage

### As a consumer

```bash
# Get base
kpt pkg get https://repo1.dsop.io/platform-one/big-bang/apps/sandbox/umbrella.git/base base

# Get instance
kpt pkg get https://repo1.dsop.io/platform-one/big-bang/apps/sandbox/umbrella.git/instance bigbang

# Commit and push to a repo cluster has access to
git add . && git commit -m "initial commit" && git push

# Apply the bootstrapping resources (flux kustomizations)
# NOTE: Shell script is provided for documentation purposes as well as minor convenience (such as an envsubst for current branch)
bootstrap/init.sh
```

### For development or getting started

```bash
# Assumes valid kubeconfig is configured
# WARNING: This will deploy (a lot of) resources to the cluster configured with kubectl
bootstrap/init.sh
```

## Directory Structure

```bash
├── base                                            # (1)
|   ├── flux-system                                 # (2)
|   ├── istio
|   ├── ...
├── instance                                        # (3)
|   ├── flux-system                                 # (4)
|       ├── kustomizations                          # (5)
|   ├── istio-operator
|   ├── istio-system
|   ├── ...
```

1. Common base resources

    The `./base` folder is reserved for logical groups of packages and configuration that is common to all deployments.  When consuming a helm chart, this is almost always simply a kustomization base with a `Namespace` and `HelmRelease`.  When consuming a kustomize base, this is typically  the deployable resources packaged as a kustomize base.

2. Environment agnostic packages

    When within `./base`, packages are assumed to be logically separated by package.  For example, the `istio` package is all contained within the `./base/istio`, even though istio contains `istio-system` and `istio-operator` components, it is still logicall one application.
    
3. A consumable instance of Big Bang

    This defines a single `instance` of BigBang, which is the deployable unit of the BigBang umbrella package.  Within the `instance` contains a fully consumable deployment of BigBang, that can be easily configured either by `kpt` setters, or for more advanced use cases, kustomize overlays.  For more information on consuming and configuring the BigBang instance, please see [here](#configuring-a-big-bang-instance).
    
4. Instance structured by namespace

    The `./instance` folder represents everything deployed within your cluster.  Since the deployment is handled via gitops, the folder structure of `./instance` is laid out by namespace to provide a familiar feel.  This means that the organizational structure is _different_ than how `./base` is structured (logical packages).
    For example, `./base/istio` becomes `./instance/istio-operator` and `./instance-istio-system`.
    
    Also important to note is any environment specific configurations (such as `VirtualService` hostnames) are configured within `./instance`.  In the cases of "global" variables (such as `hostname`), these are `kpt setters`.  In the case of package specific customization, this is via kustomize overlays and helm value stacking.  More detail about configuring a Big Bang instance can be found [here](#configuring-a-big-bang-instance).
    
5. GitOps meta resources

    Meta resources are resources that define logical groupings of other resources.  When using `flux` as the gitops engine, these become `HelmReleases` and/or `Kustomizations`.  In this folder structure, all gitops bootstraps are defined by deploying a set of `Kustomizations` that point to the namespaces within `./instance`.  These `Kustomizations` are continually monitored for changes, and reconciled via the gitops engine when changes are made in git.
    
## Configuring a Big Bang Instance

An instance of Big Bang is designed to be pre-configured according to best practices.  However, any consumption of the instance will have a few required "global" variables that need to be set, as well as be extensible enough to customize for the use cases where the defaults are not sufficient.

In general, there are 2 primary methods of configuring a big bang instance, with increasing levels of complexity.

### `kpt` setters

Within the `./instance` folder, each namespace contains a `Kptfile` that defines (using the OpenAPI schema) _what_ variables are available for configuration.  The following commands will help get you started:

```bash
# List all available setters by recursively traversing all kpt packages
kpt cfg list-setters instance/ -R

# Recursively configure a setter across all kpt packages
kpt cfg set instance hostname --value "p1.dev" -R
```

For a full guide on setters, please see the kpt documentation [here](https://googlecontainertools.github.io/kpt/guides/consumer/set/).

Note that after setting a value, you should/must commit these changes. `kpt` will strategically handle future updates, more info on that is in the [updating](#updating-a-big-bang-instance) section.
    
### Kustomize overlays
    
For the more advanced use cases, additional configurations are all performed via kustomize overlays.  Note that since the primary deployment method is via meta controllers (ie `Kustomizations` and `HelmReleases` for `flux`), kustomize overlays can refer either to the traditional overlays, or overlaying helm values.

#### Traditional overlays

For packages packaged as kustomize bases, simple `overlays` can be used to modify the instance deployment.  For example, to add an additional ingressgateway for istio, a `patchesStrategicMerge` can be placed in `./instances/istio-system` that patches the `IstioOperator` defined in `./base/istio/istio-system`. 

#### Helm overlays

For `flux` specifically, all helm charts are deployed via a `Kustomization` pointing to a `HelmRelease`.  To modify a package packaged as a helm chart, simply creating a `patchesStrategicMerge` to overlay the `spec.values` in the `HelmRelease` provides all the flexibility needed to modify the upstream helm chart.  If additions not in the upstream helm chart are required, remember that everything is just kustomize, and additional resources can be added _alongside_ the chart and included as `resources`.

#### Helm `ConfigMap` and `Secret` overlays

For `flux` specifically, the `HelmRelease` spec supports a [`valuesFrom`](https://toolkit.fluxcd.io/components/helm/helmreleases/#values-overrides) field, which defines data groups from which `HelmRelease` will source values from.  All `HelmReleases` within `./base` have an _optional_ `ConfigMap` and `Secret` defined named `env-values`.  If desired, adding group resources matching that name provide another (potentially more dynamic) method of providing values to the `HelmRelease`.

## Updating a Big Bang Instance

Since Big Bang instances are consumed via `kpt`, performing upgrades is safe, easy, and where `kpt` really shines.  

Because `kpt` packages strictly operate on structured data (yaml with OpenAPI), different packages can be strategically merged together by evaluating the resulting _structure_ of the data.  If this sounds familiar, it's because it is conceptually similar to `kubectl apply`.  You can read more about it [here](https://googlecontainertools.github.io/kpt/guides/consumer/update/#topics).

The recommended way of performing an upgrade is to perform a strategic merge between _your_ instance of Big Bang vs the upstream Big Bang:

```bash
kpt pkg update instance/ --strategy=resource-merge
```

`kpt` will merge the upstream changes with your local changes, ensuring the resultant is a structured merge of the two.  This results in updating your local copy with upstream changes, assuming you haven't already updated your local copy.

TODO: Since this is critical to the whole "why use `kpt`", add more docs on how/why this actually works.

## FAQ

### `helm` excels at generic templating, why not package the umbrella with that?

Without the TLC of `helm-hooks`, helm cannot sequence rollouts and therefore cannot contain custom resources that are not currently registered in the cluster (across multiple charts, it is straightforward to `helm install` a chart which defines its _own_ crds).  Since a `HelmRelease` is nothing more than a `helm install`, it has the same shortcomings of not being able to eventually reconcile dependencies.  Using `Kustomizations` as the umbrella package ensures that all sorts of interdependent resources can be thrown at the apiserver and gotk will continually attempt to reconcile individual resources.

In practice, this allows us to mix and match generic k8s resources with `HelmReleases` that depend on each other, and creates a much cleaner and less error prone developer experience combined with gotk's `dependsOn` capability (no more sync waves!!).

That being said... helm is still the leader (and biggest failure?) in generic templating capabilities, something which is highly desirable for an umbrella package, where a simple interface for users to tune knobs affecting the deployment is critical.  To get around this deficiency, we leverage the extremely well supported and intuitive ([I'm kidding](https://github.com/kubernetes-sigs/kustomize/issues/2052)) variable substitution in kustomize.

In reality, there are very few truly "global" variables that need to be defined, and it is usually best practice to avoid the overuse of global variables.  By sparsely defining global variables, and fully leveraging the `valuesFrom` capability in `HelmReleases`, the end result is a best from both worlds scenario.  For the vast majority of users, defining the few required `global` variables is all that is required, while the advanced users can configure till their hearts content with `valuesFrom` and generic kustomize overlays.

### Why not use ArgoCD?

ArgoCD is _great_, it has an extremely user friendly UI, customizable deployment strategy, and a highly effective declarative approach to just about everything.

However, it falls short in a couple key areas, most notably in the eventual reconciliation of dependent reosurces, and it's shim between `helm` and raw manifests.

When designing an application or set of applications that explicitly depend on one another in ArgoCD, special care is needed to ensure the `sync-waves` are ordered and sequenced appropriately.  With simple dependencies, such as ensuring `istio` is installed before an app reliant on it's sidecar injection, the process is straightforward.  However, as more complicated deployments begin to arise, especially during the recommended `app of apps` approach, managing the rollout sequence becomes tricky and error prone.

In addition to that, even with the newly minted `retry` capability, deploying a combination of resources that depend on each other and expecting eventual reconciliation is not possible.  For example, deploying an `Application` that deploys the `Prometheus` operator alongside `ServiceMonitor` resources will never reconcile, and appropriate `sync-waves` are needed to ensure a successful application.

As helm installs become increasingly feature rich (aka needlessly complex?), the decision to have ArgoCD _understand_ helm features instead of using helm to install makes cert helm features extremely prone to errors.  A common example is the [Gitlab](https://gitlab.com/gitlab-org/charts/gitlab) helm chart, which relies on one time secret generation from a subchart before the rest of the application/charts can properly boot.  However, since ArgoCD handles the helm post-hook delete at the individual chart level instead of the parent chart level like helm does, the chart fails to deploy.  Overall, consuming common COTS/FOSS helm charts becomes risky business simply due to the fact that ArgoCD supports it's own helm shim instead of just helm.

The gitops toolkit takes a simpler approach to gitops, and simply acts as the gitops reconciliation engine for existing battle hardened kubernetes concepts, `helm` and `kustomize`.  The deployment itself is drastically less complex (both a good and bad thing), and nicely translates to existing kubernetes concepts.  When a `HelmRelease` is installed, you can expect that under the hood, a `helm install` is being done, and can verify as such with a `helm ls`.  This also _guarantees_ that the results you would expect from a `helm install` are the same as what you would get from applying a `HelmRelease`.  In addition, eventual reconciliation is vastly improved.... add more about this.
