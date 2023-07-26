# K3d

```
curl -L https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml -O > weave.yaml
```

Weave expects `/etc/machine-id` to be a file, and each k3d node needs to have a unique value in this file.

BB k3d uses the 172.21.0.0/16 cidr subnet for pods, so `IPALLOC_RANGE` needs to match:
 
```
          containers:
            - name: weave
              env:
                - name: IPALLOC_RANGE
                  value: "172.21.0.0/16"
```
