# Nexus Repository

[Nexus Repository OSS](https://www.sonatype.com/nexus-repository-oss) provides universal support for all major build tools.

- Store and distribute Maven/Java, npm, NuGet, Helm, Docker, p2, OBR, APT, Go, R, Conan components and more.
- Manage components from dev through delivery: binaries, containers, assemblies, and finished goods.
- Support for the Java Virtual Machine (JVM) ecosystem, including Gradle, Ant, Maven, and Ivy.
- Compatible with popular tools like Eclipse, IntelliJ, Hudson, Jenkins, Puppet, Chef, Docker, and more.

*Efficiency and Flexibility to Empower Development Teams*

- Streamline productivity by sharing components internally.
- Gain insight into component security, license, and quality issues.
- Build off-line with remote package availability.
- Integrate with industry-leading build tools.
---

## Introduction

This chart installs a single Nexus Repository instance within a Kubernetes cluster that has a single node (server) configured. It is not appropriate for a resilient Nexus Repository deployment. Refer to our [resiliency documentation](https://help.sonatype.com/repomanager3/planning-your-implementation/resiliency-and-high-availability) for information about resilient Nexus Repository deployment options.

Use the checklist below to determine if this Helm chart is suitable for your deployment needs.

### When to Use This Helm Chart
Use this Helm chart if you are doing any of the following:
- Deploying either Nexus Repository Pro or OSS to an on-premises environment with bare metal/VM server (Node)
- Deploying a single Nexus Repository instance within a Kubernetes cluster that has a single Node configured

> **Note**: If you are using Nexus Repository Pro, your license file and embedded database will reside on the node and be mounted on the container as a Persistent Volume (required).


### When Not to Use This Helm Chart
Do not use this Helm chart and, instead, refer to our [resiliency documentation](https://help.sonatype.com/repomanager3/planning-your-implementation/resiliency-and-high-availability) if you are doing any of the following:

- Deploying Nexus Repository Pro to a cloud environment with the desire for automatic failover across Availability Zones (AZs) within a single region
- Planning to configure a single Nexus Repository Pro instance within your Kubernetes/EKS cluster with two or more nodes spread across different AZs within an AWS region
- Using an external PostgreSQL database

> **Note**: A Nexus Repository Pro license is required for our resilient deployment options. Your Nexus Repository Pro license file must be stored externally as either mounted from AWS Secrets/Azure Key Vault in AWS/Azure deployments or mounted using Kustomize for on-premises deployments (required).

> **Note**: We do not currently provide Helm charts for our resilient deployment options.

---

## Prerequisites for This Chart

- Kubernetes 1.19+
- PV provisioner support in the underlying infrastructure
- Helm 3

### With Open Docker Image

By default, this Chart uses Sonatype's Public Docker image. If you want to use a different image, run with the following: `--set nexus.imageName=<my>/<image>`.

## Adding the Sonatype Repository to your Helm

To add as a Helm Repo
```helm repo add sonatype https://sonatype.github.io/helm3-charts/```

---

## Testing the Chart
To test the chart, use the following:
```bash
$ helm install --dry-run --debug --generate-name ./
```
To test the chart with your own values, use the following:
```bash
$ helm install --dry-run --debug --generate-name -f myvalues.yaml ./ 
```

---

## Installing the Chart

To install the chart, use the following:

```bash
$ helm install nexus-rm sonatype/nexus-repository-manager [ --version v29.2.0 ]
```

The above command deploys Nexus Repository on the Kubernetes cluster in the default configuration.

You can pass custom configuration values as follows:

```bash
$ helm install -f myvalues.yaml sonatype-nexus ./
```

The default login is randomized and can be found in `/nexus-data/admin.password` or you can get the initial static passwords (admin/admin123)
by setting the environment variable `NEXUS_SECURITY_RANDOMPASSWORD` to `false` in your `values.yaml`.
 
---

## Uninstalling the Chart

To uninstall/delete the deployment, use the following:

```bash
$ helm list
NAME                    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                           APP VERSION
plinking-gopher         default         1               2021-03-10 15:44:57.301847 -0800 PST    deployed        nexus-repository-manager-29.2.0 3.29.2     
$ helm delete plinking-gopher
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

---

## Configuration

The following table lists the configurable parameters of the Nexus chart and their default values.

| Parameter                                  | Description                                                                                  | Default                                                                                                                                         |
|--------------------------------------------|----------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|
| `deploymentStrategy`                       | Deployment Strategy                                                                          | `Recreate`                                                                                                                                      |
| `nexus.imagePullPolicy`                    | Nexus Repository image pull policy                                                           | `IfNotPresent`                                                                                                                                  |
| `imagePullSecrets`                         | The names of the kubernetes secrets with credentials to login to a registry                  | `[]`                                                                                                                                            |
| `nexus.docker.enabled`                     | Enable/disable Docker support                                                                | `false`                                                                                                                                         |
| `nexus.docker.registries`                  | Support multiple Docker registries                                                           | (see below)                                                                                                                                     |
| `nexus.docker.registries[0].host`          | Host for the Docker registry                                                                 | `cluster.local`                                                                                                                                 |
| `nexus.docker.registries[0].port`          | Port for the Docker registry                                                                 | `5000`                                                                                                                                          |
| `nexus.docker.registries[0].secretName`    | TLS Secret Name for the ingress                                                              | `registrySecret`                                                                                                                                |
| `nexus.env`                                | Nexus Repository environment variables                                                       | `[{INSTALL4J_ADD_VM_PARAMS: -Xms1200M -Xmx1200M -XX:MaxDirectMemorySize=2G -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap}]` |
| `nexus.resources`                          | Nexus Repository resource requests and limits                                                | `{}`                                                                                                                                            |
| `nexus.nexusPort`                          | Internal port for Nexus Repository service                                                   | `8081`                                                                                                                                          |
| `nexus.securityContext`                    | Security Context (for enabling official image use `fsGroup: 2000`)                           | `{}`                                                                                                                                            |
| `nexus.labels`                             | Service labels                                                                               | `{}`                                                                                                                                            |
| `nexus.podAnnotations`                     | Pod Annotations                                                                              | `{}`                                                                                                                                            |
| `nexus.livenessProbe.initialDelaySeconds`  | LivenessProbe initial delay                                                                  | 30                                                                                                                                              |
| `nexus.livenessProbe.periodSeconds`        | Seconds between polls                                                                        | 30                                                                                                                                              |
| `nexus.livenessProbe.failureThreshold`     | Number of attempts before failure                                                            | 6                                                                                                                                               |
| `nexus.livenessProbe.timeoutSeconds`       | Time in seconds after liveness probe times out                                               | `nil`                                                                                                                                           |
| `nexus.livenessProbe.path`                 | Path for LivenessProbe                                                                       | /                                                                                                                                               |
| `nexus.readinessProbe.initialDelaySeconds` | ReadinessProbe initial delay                                                                 | 30                                                                                                                                              |
| `nexus.readinessProbe.periodSeconds`       | Seconds between polls                                                                        | 30                                                                                                                                              |
| `nexus.readinessProbe.failureThreshold`    | Number of attempts before failure                                                            | 6                                                                                                                                               |
| `nexus.readinessProbe.timeoutSeconds`      | Time in seconds after readiness probe times out                                              | `nil`                                                                                                                                           |
| `nexus.readinessProbe.path`                | Path for ReadinessProbe                                                                      | /                                                                                                                                               |
| `nexus.hostAliases`                        | Aliases for IPs in /etc/hosts                                                                | []                                                                                                                                              |
| `nexus.properties.override`                | Set to true to override default nexus.properties                                             | `false`                                                                                                                                         |
| `nexus.properties.data`                    | A map of custom nexus properties if `override` is set to true                                | `nexus.scripts.allowCreation: true`                                                                                                             |
| `ingress.enabled`                          | Create an ingress for Nexus Repository                                                       | `false`                                                                                                                                         |
| `ingress.annotations`                      | Annotations to enhance ingress configuration                                                 | `{kubernetes.io/ingress.class: nginx}`                                                                                                          |
| `ingress.tls.secretName`                   | Name of the secret storing TLS cert, `false` to use the Ingress' default certificate         | `nexus-tls`                                                                                                                                     |
| `ingress.path`                             | Path for ingress rules. GCP users should set to `/*`.                                        | `/`                                                                                                                                             |
| `tolerations`                              | tolerations list                                                                             | `[]`                                                                                                                                            |
| `config.enabled`                           | Enable configmap                                                                             | `false`                                                                                                                                         |
| `config.mountPath`                         | Path to mount the config                                                                     | `/sonatype-nexus-conf`                                                                                                                          |
| `config.data`                              | Configmap data                                                                               | `nil`                                                                                                                                           |
| `deployment.annotations`                   | Annotations to enhance deployment configuration                                              | `{}`                                                                                                                                            |
| `deployment.initContainers`                | Init containers to run before main containers                                                | `nil`                                                                                                                                           |
| `deployment.postStart.command`             | Command to run after starting the container                                                  | `nil`                                                                                                                                           |
| `deployment.terminationGracePeriodSeconds` | Update termination grace period (in seconds)                                                 | 120s                                                                                                                                            |
| `deployment.additionalContainers`          | Add additional Container                                                                     | `nil`                                                                                                                                           |
| `deployment.additionalVolumes`             | Add additional Volumes                                                                       | `nil`                                                                                                                                           |
| `deployment.additionalVolumeMounts`        | Add additional Volume mounts                                                                 | `nil`                                                                                                                                           |
| `secret.enabled`                           | Enable secret                                                                                | `false`                                                                                                                                         |
| `secret.mountPath`                         | Path to mount the secret                                                                     | `/etc/secret-volume`                                                                                                                            |
| `secret.readOnly`                          | Secret readonly state                                                                        | `true`                                                                                                                                          |
| `secret.data`                              | Secret data                                                                                  | `nil`                                                                                                                                           |
| `service.enabled`                          | Enable additional service                                                                    | `true`                                                                                                                                          |
| `service.name`                             | Service name                                                                                 | `nexus3`                                                                                                                                        |
| `service.labels`                           | Service labels                                                                               | `nil`                                                                                                                                           |
| `service.annotations`                      | Service annotations                                                                          | `nil`                                                                                                                                           |
| `service.type`                             | Service Type                                                                                 | `ClusterIP`                                                                                                                                     |
| `route.enabled`                            | Set to true to create route for additional service                                           | `false`                                                                                                                                         |
| `route.name`                               | Name of route                                                                                | `docker`                                                                                                                                        |
| `route.portName`                           | Target port name of service                                                                  | `docker`                                                                                                                                        |
| `route.labels`                             | Labels to be added to route                                                                  | `{}`                                                                                                                                            |
| `route.annotations`                        | Annotations to be added to route                                                             | `{}`                                                                                                                                            |
| `route.path`                               | Host name of Route e.g. jenkins.example.com                                                  | nil                                                                                                                                             |
| `serviceAccount.create`                    | Set to true to create ServiceAccount                                                         | `true`                                                                                                                                          |
| `serviceAccount.annotations`               | Set annotations for ServiceAccount                                                           | `{}`                                                                                                                                            |
| `serviceAccount.name`                      | The name of the service account to use. Auto-generate if not set and create is true.         | `{}`                                                                                                                                            |
| `persistence.enabled`                      | Set false to eliminate persistent storage                                                    | `true`                                                                                                                                          |
| `persistence.existingClaim`                | Specify the name of an existing persistent volume claim to use instead of creating a new one | nil                                                                                                                                             |
| `persistence.storageSize`                  | Size of the storage the chart will request                                                   | `8Gi`                                                                                                                                           |

### Persistence

By default, a `PersistentVolumeClaim` is created and mounted into the `/nexus-data` directory. In order to disable this functionality, you can change the `values.yaml` to disable persistence, which will use an `emptyDir` instead.

> *"An emptyDir volume is first created when a Pod is assigned to a Node, and exists as long as that Pod is running on that node. When a Pod is removed from a node for any reason, the data in the emptyDir is deleted forever."*

## Using the Image from the Red Hat Registry

To use the [Nexus Repository Manager image available from Red Hat's registry](https://catalog.redhat.com/software/containers/sonatype/nexus-repository-manager/594c281c1fbe9847af657690),
you'll need to:
* Load the credentials for the registry as a secret in your cluster
  ```shell
  kubectl create secret docker-registry redhat-pull-secret \
    --docker-server=registry.connect.redhat.com \
    --docker-username=<user_name> \
    --docker-password=<password> \
    --docker-email=<email>
  ```
  See Red Hat's [Registry Authentication documentation](https://access.redhat.com/RegistryAuthentication)
  for further details.
* Provide the name of the secret in `imagePullSecrets` in this chart's `values.yaml`
  ```yaml
  imagePullSecrets:
    - name: redhat-pull-secret
  ```
* Set `image.name` and `image.tag` in `values.yaml`
  ```yaml
  image:
    repository: registry.connect.redhat.com/sonatype/nexus-repository-server
    tag: 3.39.0-ubi-1
  ```

---
