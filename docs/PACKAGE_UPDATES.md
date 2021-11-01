# How to Sync with Upstream

Since the mattermost operator chart is built and maintained by Big Bang syncing with upstream is not as straight forward as a `kpt pkg update`.

1. Run `kpt pkg update docs/upstream@{NEW OPERATOR TAG}`. Notice that this updates the folder `docs/upstream`.

2. Incrementally copy the CRD sections from `docs/upstream/mattermost-operator.yaml` into their respective files in `chart/mattermost-operator-crds` (it can be helpful to search for `---` to find the sections). File names match the CRD names.

3. Modify each CRD file to add labels and remove `creationTimestamp: null`. Labels to add:

```yaml
  labels:
    app.kubernetes.io/managed-by: '{{ .Release.Service }}'
    app.kubernetes.io/instance: '{{ .Release.Name }}'
    app.kubernetes.io/version: '{{ .Chart.AppVersion }}'
    helm.sh/chart: '{{ .Chart.Name }}-{{ .Chart.Version }}'
```

4. Update `chart/mattermost-operator-crds/Chart.yaml` `version` and `appVersion` to the new operator version.

5. Update the versions for `chart/Chart.yaml` to the new operator version (`version`, `appVersion`, and dependency `version`).

6. Run `helm dependency update chart` and validate that the new CRD chart tgz is under `chart/charts`.

7. Incrementally copy out the remaining sections from ``docs/upstream/mattermost-operator.yaml` into their respective files in `chart/templates`. File names match the kind.

8. Modify each to add labels and remove `creationTimestamp: null`. Any spot where `namespace:` if referenced should become `{{ .Release.Namespace }}` instead of hardcoded `mattermost-operator`. As before, the labels to add:

```yaml
  labels:
    app.kubernetes.io/managed-by: '{{ .Release.Service }}'
    app.kubernetes.io/instance: '{{ .Release.Name }}'
    app.kubernetes.io/version: '{{ .Chart.AppVersion }}'
    helm.sh/chart: '{{ .Chart.Name }}-{{ .Chart.Version }}'
```

For the deployment also make sure that you maintain the existing values mapping for `replicas`, `image`, `resources`, `imagePullSecrets`, `nodeSelector`, `affinity`, and `tolerations`.

9. Modify `chart/values.yaml` to use the latest image under `image.tag`.

10. Add a changelog entry for the Chart version.

11. Open an MR on Repo1 and validate that all changes look as expected in the diffs and CI passes. Make any necessary changes if something looks off or CI fails.
