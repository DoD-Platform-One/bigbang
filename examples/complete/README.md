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

# Decrypt the Big Bang Development Wildcard Cert
sops -d envs/dev/secrets/ingress-cert.yaml

# Encrypt the Big Bang Development Wildcard Cert
sops -e envs/dev/secrets/ingress-cert.yaml
```

## Development Workflow

This example is also intended to serve as a development environment for developing against the umbrella chart.

To set up your local development environment, follow the steps below:

```bash
# Create a local k3d cluster with the appropriate port forwards
k3d cluster create --k3s-server-arg "--disable=traefik" --k3s-server-arg "--disable=metrics-server" -p 80:80@loadbalancer -p 443:443@loadbalancer

# Deploy the latest fluxv2 with iron bank images
kubectl apply -f https://repo1.dsop.io/platform-one/big-bang/apps/sandbox/fluxv2/-/raw/master/flux-system.yaml

# Apply a local version of the umbrella chart
# NOTE: This is the alternative to deploying a HelmRelease and having flux manage it, we use a local copy to avoid having to commit every change
# NOTE: Use yq to parse the kustomize values patch and pipe it to the helm values
yq r examples/complete/envs/dev/patch-bigbang.yaml 'spec.values' | helm upgrade -i bigbang chart -n bigbang --create-namespace -f -

# Apply the necessary dev secrets
# NOTE: You should do this immediately after the previous helm command in case there are any secrets that the helm charts require to boot
# NOTE: Flux will take care of the reconcilitation and retry loops for us, it is normal to see resources fail to deploy a few times on boot
kubectl apply -f examples/complete/envs/dev/source-secrets.yaml

# After making changes to the umbrella chart or values, you can update the chart idempotently
yq r examples/complete/envs/dev/patch-bigbang.yaml 'spec.values' | helm upgrade -i bigbang chart -n bigbang --create-namespace -f -

# A convenience development script is provided to force fluxv2 to reconcile all helmreleases within the cluster
hack/sync.sh
```

## DNS Entries

The owner of bigbang.dev has set the virtual service dns records:

```bash
$  dig kiali.bigbang.dev              

; <<>> DiG 9.10.6 <<>> kiali.bigbang.dev
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 60209
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;kiali.bigbang.dev.             IN      A

;; ANSWER SECTION:
kiali.bigbang.dev.      3600    IN      A       127.0.0.1

;; Query time: 225 msec
;; SERVER: 10.0.0.1#53(10.0.0.1)
;; WHEN: Tue Nov 10 11:19:08 EST 2020
;; MSG SIZE  rcvd: 62
```

so that if the cluster is deployed locally with port forwarding, a browser can be used to test the functionality of the virtual services:
