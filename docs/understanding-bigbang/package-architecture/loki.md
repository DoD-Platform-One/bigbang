# Loki

Loki is a horizontally-scalable, highly-available, multi-tenant log aggregation system inspired by Prometheus. It is designed to be very cost effective and easy to operate. It does not index the contents of the logs, but rather a set of labels for each log stream. Loki is like Prometheus, but for logs: we prefer a multidimensional label-based approach to indexing, and want a single-binary, easy to operate system with no dependencies. Loki does require a forwarder to ship logs into it's database.

## Monolith

```mermaid
flowchart TD
   S3[(S3)]
   Alloy/FluentBit--> Loki
   Grafana --> Loki --> S3
```

## (Simple) Scalable
```mermaid
flowchart TD
   S3[(S3)]
   read[Loki Read] --> S3
   write[Loki Write]
   Alloy/FluentBit--> write --> S3
   Grafana --> read
```

## Monolith with Grafana Enterprise Logging (GEL)
```mermaid
flowchart TD
   subgraph Enterprise
   g[GEL Gateway] --> a[Admin API]  
   a[Admin API]
   end
   Alloy/FluentBit--> g[GEL Gateway] --> Loki --> S3
   Grafana --> g[GEL Gateway]
```

## Simple Scalable Enterprise with Grafana Enterprise Logging (GEL)
```mermaid
flowchart TD
   subgraph Enterprise
   g[GEL Gateway] --> a[Admin API]  
   a[Admin API]
   end 
   S3[(S3)]
   read[Loki Read] --> S3
   write[Loki Write]
   Logs--> g[GEL Gateway] --> gateway
   gateway[Loki Gateway] --> read
   gateway --> write --> S3
   Grafana --> g[GEL Gateway]
```


## Big Bang Touch Points

### Licensing

Loki utilizes an AGPLv3 License for it's code and binaries. By default the application does not need a license out of the box but can be utilized with [Grafana Enterprise Logs](https://grafana.com/products/enterprise/logs/) that can be deployed in the Grafana Cloud or in-cluster. Big Bang will be adding in support for both implementations of Grafana Enterprise Logs.

### Single Sign On

Loki utilizes Grafana as the frontend for searching and viewing logs, please refer to the [monitoring package for Single Sign On capabilities](monitoring.md).

### High Availability

Since Big Bang release 1.32.0 a Big Bang value `loki.strategy` has been available. When set to `scalable` Loki is configured to run with multiple replicas of what are called read and write nodes. The read nodes are what schedule, process and return queries to/from the Loki API while the write nodes is where your configured log forwarder will send the logs to and process write/create operations against the API and storage.

```yaml
loki:

  strategy: scalable

  values:
    # Configuration for the write node(s)
    write:
      # -- Number of replicas for the write
      replicas: 2
    # Configuration for the read node(s)
    read:
      # -- Number of replicas for the read
      replicas: 2
```

You can also optionally use HPA with Loki for each component. There are additional options for the target memory and scaling behavior that you can reference in the [package chart values](https://repo1.dso.mil/big-bang/product/packages/loki/-/blob/main/chart/values.yaml).

```yaml
loki:
  values:
    write:
      autoscaling:
        enabled: true
        # -- Minimum autoscaling replicas for the write.
        minReplicas: 1
        # -- Maximum autoscaling replicas for the write.
        maxReplicas: 3
        # -- Target CPU utilization percentage for the write.
        targetCPUUtilizationPercentage: 80
    read:
      autoscaling:
        enabled: true
        # -- Minimum autoscaling replicas for the write.
        minReplicas: 1
        # -- Maximum autoscaling replicas for the write.
        maxReplicas: 3
        # -- Target CPU utilization percentage for the write.
        targetCPUUtilizationPercentage: 80
    backend:
      autoscaling:
        enabled: true
        # -- Minimum autoscaling replicas for the write.
        minReplicas: 1
        # -- Maximum autoscaling replicas for the write.
        maxReplicas: 3
        # -- Target CPU utilization percentage for the write.
        targetCPUUtilizationPercentage: 80
```

### UI

Loki has no UI packaged with it. Grafana is the frontend to view logs which are ingested by Loki.

### Logging

Within Big Bang, logs are captured by alloy or fluentbit and shipped to your logging engine (Loki when ECK not installed, ECK when it's installed or both).

### Health Checks

Loki pods come with a pre-configured Readiness probe to query `:3100/ready` for the pod to ensure it's healthy.

Loki package also comes bundled with a ServiceMonitor so it will show up as a Prometheus target assuming monitoring is installed and the `coreos` CRDs/APIs are available.

### Dependent Packages

When using the `scalable` deployment strategy without filling in `loki.objectStorage` values, minioOperator is required as a minio tenant will be auto-created and configured as the object storage backend.

Loki can be deployed by itself but since it's so closely tied with Grafana, the monitoring package is set as a required dependency within Big Bang so both are setup and auto-configured.

As mentioned above, Loki requires a log forwarder in the cluster to receive logs. You can use either one of alloy or fluentbit but Loki will not fail to install if neither one are installed via Big Bang.