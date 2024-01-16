# Deploying BigBang and BigBang packages using Signed HelmRepository artifacts

## Artifact Signing Introduction

Kubernetes and Flux2 both support ways to verify artifacts are signed according to the SigStore Cosign signature published with their Release Artifacts on Gitlab.

As part of the existing BigBang Releases, packages and BigBang Release artifacts will now also have  cosign signatures published to registry1. This is only available for use when your packages are set to use `sourceType: helmRepo` (default is "git"). Combined with `<package_name>.helmRepo.cosignVerify: true` flux2 will verify signatures of HelmRepositories installed in the cluster.

The following example shows how to configure and enable public key verification for Helm Repositories:

```yaml
helmRepositories:
  - name: "registry1"
    repository: "oci://registry1.dso.mil/bigbang"
    existingSecret: "private-registry"
    type: "oci"
    username: ""
    password: ""
    email: ""
    cosignPublicKeys:
      key1: |
        -----BEGIN PUBLIC KEY-----
        MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEIE7v9J6ttQus6itUoyfMCqMjaIqm
        R8XrntaedsdEhPPchOQuFzqTyyAPGifV1SaEu8medVRi6mVICWbVwOteNg==
        -----END PUBLIC KEY-----
  - name: "registry2"
    repository: "oci://registry1.dso.mil/bigbang"
    existingSecret: "private-registry"
    type: "oci"
    username: ""
    password: ""
    email: ""
    cosignPublicKeys:
      registry2-key: |
        -----BEGIN PUBLIC KEY-----
        ...
        -----END PUBLIC KEY-----
      registry2-key2: |
        -----BEGIN PUBLIC KEY-----
        ...
        -----END PUBLIC KEY-----
  - name: "registry3"
    repository: "oci://registry1.dso.mil/bigbang"
    existingSecret: "private-registry"
    type: "oci"
    username: ""
    password: ""
    email: ""
    cosignPublicKeys: []
  - name: "registry4"
    repository: "oci://registry1.dso.mil/bigbang"
    existingSecret: "private-registry"
    type: "oci"
    username: ""
    password: ""
    email: ""
    cosignPublicKeys: 
      registry4-public: |
        -----BEGIN PUBLIC KEY-----
        ...
        -----END PUBLIC KEY-----

istio:
  sourceType: "helmRepo"
  helmRepo:
    cosignVerify: true

istioOperator:
  sourceType: "helmRepo"
  helmRepo:
    cosignVerify: true

kiali:
  sourceType: "helmRepo"
  helmRepo:
    repoName: "registry2" 
    cosignVerify: true

kyverno:
  sourceType: "helmRepo"
  helmRepo:
    repoName: "registry3"
    cosignVerify: true
```

## More Reading

- [FluxCD Documentation on public key verification](https://fluxcd.io/flux/components/source/ocirepositories/#public-keys-verification)
- [Kubernetes.io Documenation on cosign signatures](https://kubernetes.io/docs/tasks/administer-cluster/verify-signed-artifacts/#verifying-image-signatures)
