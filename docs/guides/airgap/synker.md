# Airgap Image Sync

## Prerequisite

- `images.tar.gz` from [Big Bang Releases](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/releases)
- 40gb disk space
- docker

## Usage

Unpack

```shell
tar -xvf images.tar.gz
```

Start a local registry based on the images we just unpacked.

```shell
cd ./var/lib/registry
docker load < registry.tar
docker run -p 25000:5000 -v $(pwd):/var/lib/registry registry:2
# Verify the registry mounted correctly
curl http://localhost:25000/v2/_catalog -k
# A list of Big Bang images should be displayed, if not check the volume mount of the registry
```

Configure `./synker.yaml`

Example:

```yaml
destination:
  registry:
    # Hostname of the destination registry to push to
    hostname: 10.0.0.10
    # Port of the destination registry to push to
    port: 5000
```

If using Harbor, reference the project name.

```yaml
destination:
  registry:
    # Hostname of the destination registry to push to
    hostname: harbor.domain.com/ironbank
    # Port of the destination registry to push to
    port: 443
```

If your destination repo requires credentials add them to `~/.docker/config.json`

```json
{
  "auths": {
    "registry.dso.mil": {
      "username": "gitlab -user",
      "password": "",
      "auth": "=="
    },
    "registry1.dso.mil": {
      "auth": ""
    },
    "harbor.yourdomain.com": {
      "username": "robot",
      "password": "",
      "auth": "base64(username:password)="
    }
  }
}
```

**WARNING:** Verify your credentials with docker login before running synker. If your environment has login lockout after failed attempts synker could trigger a lockout if your credentials are incorrect.

```shell
./synker push
```

Verify the images were pushed to your registry.
