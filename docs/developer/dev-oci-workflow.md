# Dev Workflow with OCI

⚠️ **NOTE: This doc is a work in progress as OCI is not the expected or default workflow in Big Bang yet. Changes might be made to the structure or process at any time.** ⚠️

If you want to test deployment of a package off of your dev branch you have two options. This doc covers the OCI workflow, the Git workflow requires nothing more than the values specified in [example git values](../assets/configs/example/git-repo-values.yaml) pointed to your development branch.

## Package Chart for OCI

After making your changes to a chart you will need to package it with `helm package chart`. You should see output similar to the below:

```console
Successfully packaged chart and saved it to: /Users/me/bigbang/anchore/anchore-1.19.7-bb.4.tgz
```

Note that Helm strictly enforces the OCI name and tag to match the chart name and version (see [HIP 0006](https://github.com/helm/community/blob/main/hips/hip-0006.md#3-chart-versions--oci-reference-tags)), and artifacts will always match the above syntax.

## Pushing OCI "somewhere"

In order to use this OCI artifact you will need to push it to an OCI compatible registry. You have a couple options here.

### Push to self-hosted docker registry

The preferred option for OCI storage is in your own personal registry. We can do this by running a registry with the standard docker `registry:2` image. Note that we have to host this as a TLS registry due to limitations with Helm.

You will want to spin up the registry on the same host as your cluster, i.e. your ec2 instance if following the normal developer workflow.

TODO: Make this all happen with a flag in the dev script, this should not be too challenging to automate.

1. Grab the `*.bigbang.dev` cert to use for the registry. If you follow the commands below, using `curl` and `yq`, this is pretty easy.

    ```console
    mkdir certs
    curl -sS https://repo1.dso.mil/platform-one/big-bang/bigbang/-/raw/master/chart/ingress-certs.yaml | yq '.istio.gateways.public.tls.key' > certs/tls.key
    curl -sS https://repo1.dso.mil/platform-one/big-bang/bigbang/-/raw/master/chart/ingress-certs.yaml | yq '.istio.gateways.public.tls.cert' > certs/tls.crt
    ```

1. Setup a docker registry, mounting the certs to expose this as a TLS (HTTPS) registry.

    ```console
    docker volume create registry
    docker run -d -p 5000:5000 --restart=always --name registry \
      -v registry:/var/lib/registry \
      -v `pwd`/certs:/certs \
      -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/tls.crt \
      -e REGISTRY_HTTP_TLS_KEY=/certs/tls.key \
      registry:2
    ```

1. Spin up your development cluster as you normally would. Do not install Flux or Big Bang on top of the cluster yet.

1. Modify CoreDNS for your cluster to resolve your registry address to the private IP of your cluster host. In the example below we are using `oci.bigbang.dev`. Run the commands below from your cluster host (i.e. ec2 instance if using it):

    ```console
    # Note that these commands assume a Linux host and k3d cluster
    export PRIVATE_IP=$(hostname -I | cut -d " " -f1)
    kubectl get configmap -n kube-system coredns -o jsonpath='{.data.NodeHosts}' > newhosts
    echo "${PRIVATE_IP} oci.bigbang.dev" >> newhosts
    hosts=$(cat newhosts) yq e -n '.data.NodeHosts = strenv(hosts)' > patch.yaml
    kubectl patch configmap -n kube-system coredns --patch "$(cat patch.yaml)"
    kubectl rollout restart deployment -n kube-system coredns
    ```

1. If your cluster is not on your local machine, also modify /etc/hosts to resolve your registry address (i.e. `oci.bigbang.dev`) to your cluster/registry host's public IP.

    ```console
    # Run on your registry/cluster host to print public IP
    curl http://checkip.amazonaws.com/ 2> /dev/null

    # From developer machine add this IP to /etc/hosts
    sudo sh -c "echo '<IP from curl above> oci.bigbang.dev' >> /etc/hosts"
    ```

1. Push OCI artifact to this registry with `helm push <artifact name> oci://oci.bigbang.dev:5000`. Following this example that would look like this:

    ```console
    ❯ helm push anchore-1.19.7-bb.4.tgz oci://oci.bigbang.dev:5000
    Pushed: oci.bigbang.dev:5000/anchore:1.19.7-bb.4
    Digest: sha256:3cb826ee59fab459aa3cd723ded448fc6d7ef2d025b55142b826b33c480f0a4c
    ```

1. Configure your Big Bang values to setup an additional `HelmRepository` and point the package to that repository. Then install Flux and Big Bang as you normally would.

    ```yaml
    helmRepositories:
    - name: "registry1"
      repository: "oci://registry1.dso.mil/bigbang"
      existingSecret: "private-registry"
     - name: "k3d"
       repository: "oci://oci.bigbang.dev:5000"

    addons:
      anchore:
        helmRepo:
          repoName: "k3d"
          chartName: "anchore"
          tag: "1.19.7-bb.4"
    ```

### Push to Registry1 Staging

One option is to push your OCI artifacts to the Big Bang Staging area of Registry1. This is a SHARED area that internal Big Bang team members have access to - note that you may overwrite other developer's artifacts if you take this approach.

1. Login to registry1 with helm: `helm registry login registry1.dso.mil`. Follow the prompts to add your normal username and CLI token for registry1 auth.

    ```console
    ❯ helm registry login registry1.dso.mil
    Username: myusername
    Password: 
    Login Succeeded
    ```

1. Push OCI artifact to the staging area with `helm push <artifact name> oci://registry1.dso.mil/bigbang-staging`.

    ```console
    ❯ helm push anchore-1.19.7-bb.4.tgz oci://registry1.dso.mil/bigbang-staging
    Pushed: registry1.dso.mil/bigbang-staging/anchore:1.19.7-bb.4
    Digest: sha256:3cb826ee59fab459aa3cd723ded448fc6d7ef2d025b55142b826b33c480f0a4c
    ```

1. Configure your Big Bang values to setup an additional `HelmRepository` and point the package to that repository. See example below:

    ```yaml
    helmRepositores:
    - name: "registry1"
      repository: "oci://registry1.dso.mil/bigbang"
      existingSecret: "private-registry"
      type: "oci"
    - name: "staging"
      repository: "oci://registry1.dso.mil/bigbang-staging"
      existingSecret: "private-registry"
      type: "oci"

    addons:
      anchore:
        helmRepo:
          repoName: "staging"
          chartName: "anchore
          tag: "1.19.7-bb.4"
    ```

### Push to a Big Bang registry

Note that this has a limited use case, since this requires at minimum Istio + Registry to be installed in advance. This may not work well if you are testing Istio or the registry package itself.

Currently you could leverage any of the following as your OCI registry:
- Gitlab Project Registries (in a Big Bang installed Gitlab, not Repo1)
- Nexus Registry (see CI test values for auto-creation of OCI registry)
- Harbor (currently in sandbox, but functioning well with the test values)

1. Install a minimal Big Bang on your cluster, not including the package you want to test. You should at least install Istio and the registry (Gitlab, Nexus, Harbor).

1. Modify CoreDNS for your cluster to route traffic to `x.bigbang.dev` (ex: `harbor.bigbang.dev`) to the IP of the public ingress gateway. 

1. Modify `/etc/hosts` to route `x.bigbang.dev` to the Public IP of your instance (if using a remote/ec2 based cluster).

1. Push Helm tgz to your chosen registry.

1. Configure your Big Bang values to setup an additional `HelmRepository` and point the package to that repository. 
