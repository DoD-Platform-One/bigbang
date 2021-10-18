# Nexus

[Nexus OSS](https://www.sonatype.com/nexus-repository-oss) provides universal support for all major build tools.

- Store and distribute Maven/Java, npm, NuGet, Helm, Docker, P2, OBR, APT, GO, R, Conan components and more.
- Manage components from dev through delivery: binaries, containers, assemblies, and finished goods.
- Awesome support for the Java Virtual Machine (JVM) ecosystem, including Gradle, Ant, Maven, and Ivy.
- Compatible with popular tools like Eclipse, IntelliJ, Hudson, Jenkins, Puppet, Chef, Docker, and more.

*Efficiency and Flexibility to Empower Development Teams*

- Streamline productivity by sharing components internally.
- Gain insight into component security, license and quality issues.
- Build off-line with remote package availability.
- Integrate with industry leading build tools.

## Introduction

This chart bootstraps a Nexus OSS deployment on a cluster using Helm.

## Prerequisites

- Kubernetes 1.8+ with Beta APIs enabled
- PV provisioner support in the underlying infrastructure
- Helm 3

### With Open Docker Image

By default, the Chart uses Sonatype's Public Docker image. If you want to use a different image, run with `--set nexus.imageName=<my>/<image>`.

### With Red Hat Certified container

If you're looking run our Certified Red Hat image in an OpenShift4 environment there is a Certified Operator in OperatorHub.

## Adding the repo
To Add as a Helm Repo
```helm repo add sonatype https://sonatype.github.io/helm3-charts/```

## Testing the Chart
To test the chart:
```bash
$ helm install --dry-run --debug --generate-name ./
```
To test the chart with your own values:
```bash
$ helm install --dry-run --debug --generate-name -f myvalues.yaml ./ 
```

## Installing the Chart

To install the chart:

```bash
$ helm install nexus-rm sonatype/nexus-repository-manager [ --version v29.2.0 ]
```

The above command deploys Nexus on the Kubernetes cluster in the default configuration.

You can pass custom configuration values as:

```bash
$ helm install -f myvalues.yaml sonatype-nexus ./
```

The default login is randomized and can be found in sonatype /nexus-data/admin.password
or you can override this behavior by setting an environmental variable
NEXUS_SECURITY_RANDOMPASSWORD to 'true'

## Uninstalling the Chart

To uninstall/delete the deployment:

```bash
$ helm list
NAME                    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                           APP VERSION
plinking-gopher         default         1               2021-03-10 15:44:57.301847 -0800 PST    deployed        nexus-repository-manager-29.2.0 3.29.2     
$ helm delete plinking-gopher
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the Nexus chart and their default values.

| Parameter                                   | Description                         | Default                                 |
| ------------------------------------------  | ----------------------------------  | ----------------------------------------|
| `deploymentStrategy`                        | Deployment Strategy     |  `Recreate` |
| `nexus.imagePullPolicy`                     | Nexus image pull policy             | `IfNotPresent`                          |
| `nexus.imagePullSecrets`                     | Secret to download Nexus image from private registry      | `nil`             |
| `nexus.docker.enabled`                      | Enable/disable docker support       | `false`                                  |
| `nexus.docker.registries`                   | Support multiple docker registries  | (see below)                             |
| `nexus.docker.registries[0].host`           | Host for the docker registry        | `cluster.local`                         |
| `nexus.docker.registries[0].port`           | Port for the docker registry        | `5000`                                  |
| `nexus.docker.registries[0].secretName`     | TLS Secret Name for the ingress     | `registrySecret`                        |
| `nexus.env`                                 | Nexus environment variables         | `[{install4jAddVmParams: -Xms1200M -Xmx1200M -XX:MaxDirectMemorySize=2G -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap}]` |
| `nexus.resources`                           | Nexus resource requests and limits  | `{}`                                    |
| `nexus.nexusPort`                           | Internal port for Nexus service     | `8081`                                  |
| `nexus.securityContext`                     | Security Context (for enabling official image use `fsGroup: 2000`) | `{}`     |
| `nexus.labels`                              | Service labels                      | `{}`                                    |
| `nexus.podAnnotations`                      | Pod Annotations                     | `{}`
| `nexus.livenessProbe.initialDelaySeconds`   | LivenessProbe initial delay         | 30                                      |
| `nexus.livenessProbe.periodSeconds`         | Seconds between polls               | 30                                      |
| `nexus.livenessProbe.failureThreshold`      | Number of attempts before failure   | 6                                       |
| `nexus.livenessProbe.timeoutSeconds`        | Time in seconds after liveness probe times out    | `nil`                     |
| `nexus.livenessProbe.path`                  | Path for LivenessProbe              | /                                       |
| `nexus.readinessProbe.initialDelaySeconds`  | ReadinessProbe initial delay        | 30                                      |
| `nexus.readinessProbe.periodSeconds`        | Seconds between polls               | 30                                      |
| `nexus.readinessProbe.failureThreshold`     | Number of attempts before failure   | 6                                       |
| `nexus.readinessProbe.timeoutSeconds`       | Time in seconds after readiness probe times out    | `nil`                    |
| `nexus.readinessProbe.path`                 | Path for ReadinessProbe             | /                                       |
| `nexus.hostAliases`                         | Aliases for IPs in /etc/hosts       | []                                      |
| `nexus.properties.override`                 | Set to true to override default nexus.properties | `false`                    |
| `nexus.properties.data`                 | A map of custom nexus properties if `override` is set to true | `nexus.scripts.allowCreation: true`            |
| `ingress.enabled`                           | Create an ingress for Nexus         | `true`                                  |
| `ingress.annotations`                       | Annotations to enhance ingress configuration  | `{kubernetes.io/ingress.class: nginx}`                          |
| `ingress.tls.secretName`                    | Name of the secret storing TLS cert, `false` to use the Ingress' default certificate | `nexus-tls`                             |
| `ingress.path`                              | Path for ingress rules. GCP users should set to `/*` | `/`                    |
| `tolerations`                               | tolerations list                    | `[]`                                    |
| `config.enabled`                            | Enable configmap                    | `false`                                 |	
| `config.mountPath`                          | Path to mount the config            | `/sonatype-nexus-conf`                  |	
| `config.data`                               | Configmap data                      | `nil`                                   |
| `deployment.annotations`                    | Annotations to enhance deployment configuration  | `{}`                       |
| `deployment.initContainers`                 | Init containers to run before main containers  | `nil`                        |
| `deployment.postStart.command`              | Command to run after starting the nexus container  | `nil`                    |
| `deployment.terminationGracePeriodSeconds`  | Update termination grace period (in seconds)        | 120s                    |
| `deployment.additionalContainers`           | Add additional Container         | `nil`                                      |
| `deployment.additionalVolumes`              | Add additional Volumes           | `nil`                                      |
| `deployment.additionalVolumeMounts`         | Add additional Volume mounts     | `nil`                                      |
| `secret.enabled`                            | Enable secret                    | `false`                                    |
| `secret.mountPath`                          | Path to mount the secret         | `/etc/secret-volume`                       |
| `secret.readOnly`                           | Secret readonly state            | `true`                                     |
| `secret.data`                               | Secret data                      | `nil`                                      |
| `service.enabled`                           | Enable additional service        | `true`                                     |
| `service.name`                              | Service name                     | `nexus3`                                   |
| `service.labels`                            | Service labels                   | `nil`                                      |
| `service.annotations`                       | Service annotations              | `nil`                                      |
| `service.type`                              | Service Type                     | `ClusterIP`                                |
| `route.enabled`         | Set to true to create route for additional service | `false` |
| `route.name`            | Name of route                                      | `docker` |
| `route.portName`        | Target port name of service                        | `docker` |
| `route.labels`          | Labels to be added to route                        | `{}` |
| `route.annotations`     | Annotations to be added to route                   | `{}` |
| `route.path`            | Host name of Route e.g jenkins.example.com         | nil |
| `psp.create`            | Set to true to create PodSecurityPolicy            | `false` |
| `serviceAccount.create` | Set to true to create ServiceAccount               | `true` |
| `serviceAccount.annotations` | Set annotations for ServiceAccount               | `{}` |
| `serviceAccount.name` | The name of the service account to use. Auto-generate if not set and create is true      | `{}` |

### Persistence

By default a PersistentVolumeClaim is created and mounted into the `/nexus-data` directory. In order to disable this functionality you can change the `values.yaml` to disable persistence which will use an `emptyDir` instead.

> *"An emptyDir volume is first created when a Pod is assigned to a Node, and exists as long as that Pod is running on that node. When a Pod is removed from a node for any reason, the data in the emptyDir is deleted forever."*
