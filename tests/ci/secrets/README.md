# Update certificate

## Lets Encrypt

```bash
sudo certbot certonly --manual -d "*.dev.bigbang.dev" -d "*.test.bigbang.dev" -d "*.default.bigbang.dev" -d "*.bigbang.dev" -d bigbang.dev --agree-tos --preferred-challenges dns-01
```

Copy certs:

```bash
mkdir certs
sudo cp /etc/letsencrypt/live/bigbang.dev/fullchain.pem certs/
sudo cp /etc/letsencrypt/live/bigbang.dev/privkey.pem certs/
sudo chown -R tom certs
```


## Unencrypt Cert

```bash
kubectl create secret tls public-cert -n istio-system --key=certs/privkey.pem --cert=certs/fullchain.pem --dry-run=client -oyaml > ingress-cert.yaml
```

## Recrypt Cert

```
sops --encrypt \
   --pgp=41BFF8BAF2586039F6293D835A2E820C25FE527C \
   --encrypted-regex '^(data|stringData)$' \
   --in-place ingress-cert.yaml
```

## Copy to another location

TODO we should consolidate this

```bash
cp ingress-cert.yaml ../../../hack/secrets
```
