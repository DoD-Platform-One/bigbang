# Big Bang Package: Object Storage

If the package you are integrating connects to object storage (e.g. S3 buckets), you will need to follow the instructions below to integrate this feature into Big Bang.

In BigBang MinIO is a consistent, performant and scalable object store for the cloud strategies. Minio is Kubernetes-native by design and provides S3 compatible endpoints.

## Prerequisites

Blob storage bucket available with correct permissions, or Minio Addon is enabled at the BigBang level. Alternatively, you have (1) an existing Minio Instance, or (2) AWS S3 AccessKey and SecretKey.

## Integration

There are currently 2 typical ways in bigbang that packages connect to object storage.

1. Package charts accept values for endpoint, accessKey, bucket values, etc and the chart makes the necessary secret, configmap etc.

2. Package chart accepts a secret name where all the object storage connection info is defined. In these cases we make the secret in the BB chart.

Both ways will first require the following step:

Add objectStorage values for the package in bigbang/chart/values.yaml

  Notes:

- Names of key/values may differ based on the application being integrated (eg: iamProfile for Gitlab objectStorage values). Please refer to package chart values to ensure key/values coincide and application documentation for additional information on connecting to object storage.
- Some packages may have in-built object storage and the implementation may vary.

```yaml
<package>
  objectStorage:
    # -- Type of object storage to use for Gitlab, setting to s3 will assume an external, pre-existing object storage is to be used.
    # Entering connection info will enable this option and will auto-create any required secrets
    type: "s3" 

    # -- S3 compatible endpoint to use for connection information.
    endpoint: "https://s3.amazonaws.com"

    # -- S3 compatible region to use for connection information.
    region: ""

    # -- Access key for connecting to object storage endpoint.
    # -- If using accessKey and accessSecret, the iamProfile must be left as an empty string: ""
    accessKey: "AHDKEJ3BYNC8B2BFJ38NRB"

    # -- Secret key for connecting to object storage endpoint.
    # Unencoded string data. This should be placed in the secret values and then encrypted
    accessSecret: "LKSJF2343KS9LS21J3KK20"

    # -- Bucket prefix to use for identifying buckets.
    bucketPrefix: "prod"

    # -- NOTE: Current bug with AWS IAM Profiles and Object Storage where only artifacts are stored. Fixed in Gitlab 14.5
    # -- Name of AWS IAM profile to use.
    # -- If using an AWS IAM profile, the accessKey and accessSecret values must be left as empty strings eg: ""
    iamProfile: ""
```

**Options for packages connecting to a pre-existing object storage.**

1. Package charts accept values for endpoint, accessKey, bucket values, etc. and the chart makes the necessary secret, configmap etc...

- add a conditional statement to `bigbang/chart/templates/<package>/values` that will check if the object storage values exist and creates the necessary object storage values.

  If object storage values are present, then the internal object storage is disabled by setting `enabled: false` and the endpoint, accessKey, accessSecret, and bucket values are set.

  If object storage values are NOT present then the minio cluster is enabled and default values declared in the package are used.

```yaml
{{- with .Values.addons.<package>.objectStorage }}
{{- if and .endpoint .accessKey .accessSecret .bucket }}
fileStore:
  accessKey: "{{ .accessKey }}"
  accessSecret: "{{ .accessSecret }}"
  endpoint: "{{ .endpoint }}"
  bucket: "{{ .bucket }}"
{{- end }}
{{- end }}
```

Example: [MatterMost](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/chart/templates/mattermost/mattermost/values.yaml#L66-68) passes the endpoint and bucket via chart values.

1. Package chart accepts a secret name where all the object storage connection info is defined. In these cases we make the secret in the BB chart.

- add conditional statement in `chart/templates/<package>/values.yaml` to add values for object storage secret, if object storage values exist. Otherwise the minio cluster is used.

```yaml
objectStorage:
  config:
    secret: <package>-object-storage
    key: backups
```

Example: [GitLab](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/chart/templates/gitlab/values.yaml#L54-57)

- Create the secret in the Big Bang chart. (NOTE: Replace `<package>` with your package name in the example below)

```yaml
{{- if .Values.addons.<package>.enabled }}
{{- with .Values.addons.<package>.objectStorage }}
{{- if and .endpoint .accessKey .accessSecret }}
apiVersion: v1
kind: Secret
metadata:
    name: <package>-object-storage
    namespace: <package>
type: kubernetes.io/opaque
stringData:
    bucket: {{ .bucket | default "<package>-bucket" }}
    accesskey: {{ .accessKey }}
    secretkey: {{ .accessSecret }}
    endpoint: {{ .endpoint }}
{{- end }}
{{- end }}
{{- end }}
```

Example: [GitLab secret-objectstore.yaml](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/chart/templates/gitlab/secret-objectstore.yaml)

## Validation

For validating connection to the object storage in your environment or testing in CI pipeline you will need to add the object storage specific values to your overrides file or `./tests/test-values.yaml` respectively. If you are using Minio, ensure `addons.minio.enabled: true`.

Mattermost Example:

```yaml
addons:
  mattermost:
    enabled: true
    objectStorage:
      endpoint: "s3.amazonaws.com"
      accessKey: "AHDKEJ3BYNC8B2BFJ38NRB"
      accessSecret: "LKSJF2343KS9LS21J3KK20"
      bucket: "myMMBucket"
```

For testing with the CI pipeline, create a `tests/dependencies.yaml` and include Minio.

```yaml
miniooperator:
  git:
    repo: "https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio-operator.git"
    tag: "4.2.3-bb.2"
  namespace: "minio-operator"

minio:
  git:
    repo: "https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio.git"
    tag: "4.2.3-bb.6"
  namespace: minio
```

Example: [Velero dependencies.yaml](https://repo1.dso.mil/platform-one/big-bang/apps/cluster-utilities/velero/-/blob/main/tests/dependencies.yaml)

In order to test that the object storage is working, perform an action that stores a file. For example, if using Mattermost, upload an image for a user avatar.
