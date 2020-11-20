TODO
document how to use container for local package testing

### Usage
```
docker run --priviliged -d --name local-dev registry.dsop.io/platform-one/big-bang/pipeline-templates/pipeline-templates/k3d-builder-local:0.0.1
docker exec local-dev k3d cluster create package-pipeline --k3s-server-arg "--disable=metrics-server" --k3s-server-arg "--disable=traefik" -p 80:80@loadbalancer -p 443:443@loadbalancer --wait --agents 1 --servers 1
docker exec local-dev kubectl get all -A
```