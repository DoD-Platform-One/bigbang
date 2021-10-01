# MinIO

## Overview

[MinIO](https://min.io/) is an open source high performance, Kubernetes-native object storage suite is
built for the demands of the hybrid cloud.

The package is offered up as three individual packages that make up the MinIO ecosystem.

Big Bang's implementation uses the [MinIO operator](https://github.com/minio/operator) to provide custom resources and manage the different tenents of MinIO. The official package for MinIO Operator can be found [here](https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio-operator)

The MinIO tenants are created using the [MinIO package](https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio). This package is used to set up individual MinIO instances for applications to use (e.g. Gitlab).

The final package is the MinIO console. This is a graphical user interface that allows management of an individual tenant. The official package can be found [here](https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio).

![Tenant Architecture](https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio-operator/-/raw/main/upstream/operator/docs/images/architecture.png)

Note: The Minio Operator needs to be able to reach out to the minio instances. This is to ensure that on an upgrade all existing pools are shut down before starting new ones. If you run into issues with upgrades ensure that networkPolicies allow ingress to the minio pods in your namespace on port 9000.

## Big Bang Touchpoints

### UI

The MinIO Console UI is the primary way of interacting with a MinIO tenant. The UI is accessible via a web browser. The UI provides access to all of a tenants features. This includes access to features very similar to what you would see in AWS S3, setting up buckets, controlling access, etc. 


### Logging

MinIO supports configuring audit logs through both the MinIO Console UI and the MinIO `mc` command line tool. For Kubernetes environments, the MinIO Operator automatically configures the Console with a LogSearch integration for visual inspection of collected audit logs.

By default logs are also shipped to Elastic via Fluentbit for advanced searching/indexing. The filter `kubernetes.namespace_name` set to your MinIO tenant namespace can provide easy viewing of MinIO only logs.

### Monitoring

Monitoring is provided via a Prometheus capable endpoint. MinIO also provides a Grafana dashboard for use in viewing metrics. Monitoring in the Big Bang config can be enabled using the following format.

```
monitoring:
  enabled: false
  namespace: monitoring
```

### Health Checks

MinIO server exposes three un-authenticated, healthcheck endpoints [liveness probe](https://github.com/minio/minio/blob/master/docs/metrics/healthcheck/README.md#liveness-probe) and a [cluster probe](https://github.com/minio/minio/blob/master/docs/metrics/healthcheck/README.md#cluster-probe) at /minio/health/live and /minio/health/cluster respectively.


## High Availability

The default is to run in high availability. The default number of servers is 4, but can be changed by changing the values in the base Big Bang cofiguration.

```
addons:
  minio:
    values:
      tenants:
        pools:
        - servers: 8
          volumesPerServer: 4
          size: 256Mi
          resources:
            requests:
              cpu: 250m
              memory: 2Gi
            limits:
              cpu: 250m
              memory: 2Gi
          securityContext:
            runAsUser: 1001
            runAsGroup: 1001
            fsGroup: 1001
```

Note that due to the list used for the pool value you may need to include resources, requests, and securityContext so that you don't run into issues.

You can also set things like the number of volumes per server and affinity rules for the MinIO tenant.

## Single Sign On (SSO)

No current SSO is avaiable via Keycloak.

## Configuring access to Minio without SSO

Initial access to the MinIO server is via the minioRootCreds. These can be auto generated for you by adding the accesskey and secret key in your Big Bang config.

```
addons:
  minio:
    accesskey: "myaccesskey"
    secretkey: "mysecretkey"
```


## Licensing

MinIO has recently updated its license to the GNU AFFERO General Public License. This requires that any product containing usage of their product to also release their code as open source.

License can be found [here](https://github.com/minio/minio/blob/master/LICENSE)

## Storage

### File Storage

MinIO is dependent on a default storage class being configured. This is a core prereq for Big Bang itself so this should already in place when starting up the Big Bang framework. The MinIO process will need to create PersistentVolumes and PersistentVolumeClaims for its storage. The requirment for these are that they have a volumeBindingMode: WaitForFirstConsumer. The MinIO operator should take care of creating these at tenant start up.


## Dependencies

As mentioned above, MinIO needs to have access to create the needed PersistentVolumes needed for its storage. This can be EBSs in an AWS environment or a similar storage solution in place.
