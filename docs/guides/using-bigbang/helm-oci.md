# Deploying Packages with Helm Repositories

A supported alternative deployment scenario to using Flux’s GitRepository for package deployment is to use Helm OCI artifacts via the HelmRepository type. Deploying Bigbang using the OCI artifact may be beneficial if you do not want to deploy from a git repository or wish to make use of artifact verification.

### Values

The values needed for deploying a package from a HelmRepository are found in two spots in bigbang's `values.yaml`.

There is a `HelmRepositories` property which holds an array of defined helm repos.

```yaml
helmRepositories: 
  - name: "registry1"
    repository: "oci://registry1.dso.mil/bigbang"
    existingSecret: "private-registry"
    type: "oci"
    username: ""
    password: ""
    email: ""
    cosignPublicKey: |
    -----BEGIN PUBLIC KEY-----
    MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEIE7v9J6ttQus6itUoyfMCqMjaIqm
    R8XrntaedsdEhPPchOQuFzqTyyAPGifV1SaEu8medVRi6mVICWbVwOteNg==
    -----END PUBLIC KEY-----
```

The cosignPublicKey is used for [Artifact Verification](#artifact-verification); in this particular block the public key is from CNAP and is for Iron Bank Helm OCI artifacts, but this structure also supports a "bring-your-own" public/private keys.

In each package, the type should be set to `helmRepo` where the `repoName` references the array item from `helmRepositories`:

```yaml
# Example package
istio:
  sourceType: "helmRepo"
  helmRepo:
    repoName: "registry1"
    chartName: "istio"
    tag: "1.19.4-bb.0"
```

### Artifact Verification

An additional layer of secure helm chart deployment is added via verification of the OCI Helm artifacts. This checks that the OCI artifact deployed to the cluster has been signed using the expected certificate. The provider for this check is [cosign](https://github.com/sigstore/cosign). Currently, keyless signing is not performed by the bigbang build pipeline and is subsequently not a supported configuration by umbrella.

The Helm OCI artifacts found in Registry1 are signed by cosign during the build phase using a CNAP-provided certificate. 

The signature verification is enabled by default when an OCI helm repository is used and the `cosignPublicKey` field is populated. To disable this signature verification, the `cosignVerify` property will need to be set to `false` in individual package `helmRepo` sections:

```yaml
# Example package
istio:
  sourceType: "helmRepo"
  helmRepo:
    repoName: "registry1"
    chartName: "istio"
    tag: "1.19.4-bb.0"
    cosignVerify: false
```

### Note about self-hosted registries

If you are pulling these artifacts from a self-hosted registry, that registry must be using TLS due to Flux limitations ([upstream issue](https://github.com/fluxcd/source-controller/issues/807)). See [this document](https://repo1.dso.mil/big-bang/bigbang/-/blob/master/docs/developer/dev-oci-workflow.md?ref_type=heads) for guidance on configuring a registry with TLS.