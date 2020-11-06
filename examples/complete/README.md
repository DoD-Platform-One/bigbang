# Complete Example

This folder walks through all the available configuration options of Big Bang.

## Quickstart

Most production deployments follow a traditional Dev, Acceptance, Staging, Test (DAST) workflow.  This example demonstrates __one way__ of achieving multiple deployments with differing configurations.

```bash
# Apply dev
kustomize build envs/dev | kubectl apply -f -

# Apply prod
kustomize build envs/prod | kubectl apply -f -
```

## Secrets

A __development only__ gpg key is provided at `bigbang-dev.asc` that is used to encrypt and decrypt the "secret" information in `envs/dev/secrets`.

We cannot stress enough, __do not use this key to encrypt real secret data__.  It is a shared key meant to demonstrate the workflow of secrets management within Big Bang.

```bash
# Import the gpg key
gpg --import bigbang-dev.asc

# Decrypt the Big Bang Secret
sops -d envs/dev/secrets/secrets.yaml

# Encrypt the Big Bang Secret
sops -e envs/dev/secrets/secrets.yaml

```
