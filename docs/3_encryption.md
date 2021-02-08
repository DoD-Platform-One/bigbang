# Big Bang Encryption

Table of Contents

- [Big Bang Encryption](#big-bang-encryption)
  - [SOPS](#sops)
  - [Create Encryption Keys](#create-encryption-keys)
    - [Samples](#samples)
  - [Configure SOPS](#configure-sops)
  - [Deploy Private Key](#deploy-private-key)
    - [GPG](#gpg)
    - [AWS KMS](#aws-kms)
    - [GCP KMS](#gcp-kms)
    - [Azure KeyVault](#azure-keyvault)
    - [Hashicorp Vault](#hashicorp-vault)
  - [Configure Big Bang](#configure-big-bang)

Big Bang follows a [GitOps](https://www.weave.works/technologies/gitops/) approach to managing the Big Bang Kubernetes cluster configuration.  Using GitOps, we must securely store secrets in Git using encryption.  The private key, which is stored in key storage, is used by the continous deployment tool to decrypt and deploy the secrets for use in the cluster.

## SOPS

[Secrets Operations (SOPS)](https://github.com/mozilla/sops) is used to securely encrypt values in YAML, JSON, ENV, INI and BINARY formats. Secrets, such as pull credentials or certificates, should be encrypted with SOPS prior to committing into a Git repository.
> The private key used in SOPS should **NEVER** be stored in Git along side the encrypted secrets.

SOPS supports the ability to [add multiple keys](https://dev.to/stack-labs/manage-your-secrets-in-git-with-sops-common-operations-118g) to the same file so multiple key pairs can use the same secret.  This is useful for environments which may have different keys, but use the same secrets.  For each key used, SOPS writes the public key, used to encrypt, and an encrypted copy of the data to the file.  Decryption requires use of one of the private keys used.  After editing, the embedded public keys are used to re-encrypt the file for all key pairs.

## Create Encryption Keys

To setup Big Bang with SOPS, a key pair must be created.  The private key is used for decryption and must be securely stored but accessible to the cluster.  The public key is used for encryption.  Follow the appropriate instructions below to create your key pair.

| Key Management | Key Pair Instructions | Notes |
|--|--|--|
| [GNU Privacy Guard (GPG)*](https://gnupg.org/) | `gpg --full-generate-key` | Use `key type` = `RSA and RSA`, `keysize` = `4096`, `expiration` = `0` |
| [Amazon Web Services (AWS) Key Management Service (KMS)](https://aws.amazon.com/kms/) | [Link](https://github.com/mozilla/sops#2usage) | [Advanced setup help](https://github.com/mozilla/sops#26kms-aws-profiles) (e.g. roles, profiles, contexts)
| [Google Cloud Platform (GCP) Key Management Service (KMS)](https://cloud.google.com/security-key-management) | [Link](https://github.com/mozilla/sops#encrypting-using-gcp-kms) |
| [Hashicorp Vault](https://www.vaultproject.io/) | [Link](https://github.com/mozilla/sops#23encrypting-using-azure-key-vault) |

> *GPG is not recommended for production use because the private key can be misplaced or comprimised too easily

### Samples

If you plan to utilize Big Bang provided samples, either in the template or in this repository, setup the following:

1. Install [gpg](https://gnupg.org/download/)
1. Import the [Big Bang development key](../hack/bigbang-dev.asc)
   > Do **NOT** use this key for any deployment.  It is only for demonstration purposes.

   ```bash
   gpg --import <private key>
   ```

1. Validate by decrypting and opening a sample file for editing

   ```bash
   sops <filename.enc.yaml>
   ```

## Configure SOPS

SOPS uses `.sops.yaml` as a configuration file for which keys to use for newly created files.  Once a file is created, the key fingerprints are stored in the file and must be re-keyed to use any changes to `.sops.yaml`.

1. Follow the [SOPS instructions](https://github.com/mozilla/sops#210using-sopsyaml-conf-to-select-kmspgp-for-new-files) to configure `.sops.yaml` based on the encryption method you used.  Multiple keys of the same type can be added using the block scalar yaml construct, `>-`, and separating them by a comman and newline.
   > If you are using the Big Bang sample files, make sure to remove the development Big Bang key.

1. Add the following regex to only encrypt data in the yaml files

    ```yaml
    creation_rules:
    - encrypted_regex: '^(data|stringData)$'
    ```

1. Save `.sops.yaml` in the root of folder of your configuration
1. If you have existing secrets, use the following to re-key them with the configuration in `.sops.yaml`

   ```bash
   # You must have the old private key to rekey the file
   sops updatekeys <encrypted file>
   ```

## Deploy Private Key

> This must be completed before deploying Big Bang or else deploying Secrets will fail.

### GPG

1. Deploy your SOPS private key to a secret named `sops-gpg` in the cluster

   ```bash
   gpg --export-secret-keys --armor <new key fingerprint> | kubectl create secret generic sops-gpg -n bigbang --from-file=bigbangkey=/dev/stdin
   ```

### AWS KMS

TBD - [This article](https://blog.doit-intl.com/injecting-secrets-from-aws-gcp-or-vault-into-a-kubernetes-pod-d5a0e84ba892) may help to automate secret consumption in Kubernetes.

### GCP KMS

TBD - [This article](https://blog.doit-intl.com/injecting-secrets-from-aws-gcp-or-vault-into-a-kubernetes-pod-d5a0e84ba892) may help to automate secret consumption in Kubernetes.

### Azure KeyVault

TBD - [This article](https://blog.doit-intl.com/injecting-secrets-from-aws-gcp-or-vault-into-a-kubernetes-pod-d5a0e84ba892) may help to automate secret consumption in Kubernetes.

### Hashicorp Vault

TBD - [This article](https://blog.doit-intl.com/injecting-secrets-from-aws-gcp-or-vault-into-a-kubernetes-pod-d5a0e84ba892) may help to automate secret consumption in Kubernetes.

## Configure Big Bang

Big Bang needs to know how to retrieve the private key so it can deploy the encrypted secrets from Git.  Decryption configuration is placed in the top-level manifest (e.g. `dev.yaml`, `prod.yaml`) from the [Big Bang template](https://repo1.dso.mil/platform-one/big-bang/customers/template).  By default, the `Kustomization` resource uses a Secret named `sops-gpg` for the private key as shown here:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta1
kind: Kustomization
metadata:
  name: environment
spec:
  decryption:
    provider: sops
    secretRef:
      name: sops-gpg
```

TBD - Instructions on how to update for AWS, GCP, Vault
