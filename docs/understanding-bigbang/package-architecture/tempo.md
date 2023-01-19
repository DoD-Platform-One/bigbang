# Tempo

## Overview

This package contains an extensible and configurable installation of Grafana Tempo based on the upstream chart provided by grafana. Tempo can be used to collect traces from your cluster service-mesh. Grafana has a built-in data source that can be used to query Tempo and visualize traces. For production workloads, Grafana has a built in Tempo data source that can be used to query Tempo and visualize traces.

[Tempo](https://grafana.com/docs/tempo/latest/) is an open source, easy-to-use, and high-scale distributed tracing backend. With Tempo, the only dependency is object storage (e.g., S3, Azure Blob, etc.). Tempo can ingest common open source tracing protocols, including Jaeger, Zipkin, and OpenTelemetry.


### Grafana Tempo

```mermaid
flowchart LR

subgraph external
O[(Object Storage)]
end

grafana --> T["tempo"]


subgraph "tempo namespace"
    subgraph "tempo pod"
        T --> O
        Q["tempo-query"] --> T
    end
end

```

## Big Bang Touch Points

### Licensing

Tempo has no licensing options nor requirements.

### UI

Grafana is the primary frontend used to view traces. However, another option is to utilize tempo which comes with a UI package which is a jaeger frontend option in order to view traces.

### Single Sign On

Tempo-Query does not have built in SSO. In order to provide SSO, this deployment leverages Authservice

1. Create a Tempo client
   - Change the following configuration items
      - access type: confidential _this will enable a "Credentials" tab within the client configuration page_
      - Direct Access Grants Enabled: Off
      - Valid Redirect URIs: https://tracing.${DOMAIN}/login
        - If you want to deploy both Jaeger and Tempo at the same time you should set this to https://tempo.${DOMAIN}/login
      - Base URL: https://tracing.${DOMAIN}
        - If you want to deploy both Jaeger and Tempo at the same time you should set this to https://tempo.${DOMAIN}
    - Take note of the client secret in the credentials tab

2. Deploy from Big Bang with the SSO values set:
  ```yaml
  tempo:
    sso:
      enabled: true
      client_id: <id for client you created>
      client_secret: <client secret from the credentials tab>
  ```

3. Tempo will be deployed with Authservice protecting the UI behind your SSO provider.

```mermaid
flowchart LR

A --> K[(Keycloak)]

subgraph external
K
end

subgraph auth["authservice namespace"]
    A(authservice) --> K
end



ingress --> IP


subgraph "tempo namespace"
    subgraph "tempo pod"
        T["tempo-query"]
        IP["istio proxy"] --> A
        IP --> T
    end
end

```
### Storage

Tempo can utilize a local PVC for storage, but for production it is recommended to utilize in-cluster or external object-storage (e.g., GCS, S3, Azure Blob). To set a preferred object storage option in the bigang values reference the values below:

```yaml
tempo:
  enabled: true
  objectstorage:
    # -- S3 compatible endpoint to use for connection information.
    # examples: "s3.amazonaws.com" "s3.us-gov-west-1.amazonaws.com" "minio.minio.svc.cluster.local:9000"
    # Note: tempo does not require protocol prefix for URL.
    endpoint: ""

    # -- S3 compatible region to use for connection information.
    region: ""

    # -- Access key for connecting to object storage endpoint.
    accessKey: ""

    # -- Secret key for connecting to object storage endpoint.
    # Unencoded string data. This should be placed in the secret values and then encrypted
    accessSecret: ""

    # -- Bucket Names for Tempo
    # examples: "tempo-traces"
    bucket: ""

    # -- Whether or not objectStorage connection should require HTTPS, if connecting to in-cluster object
    # storage on port 80/9000 set this value to true.
    insecure: false
```

### Logging

Within Big Bang, logs are captured by fluentbit or promtail and shipped to your logging engine (Loki when ECK not installed, ECK when it's installed or both).

### Health Checks

When the global override strategy endpoint is configured within Tempo [Consistent Hash Rings](https://grafana.com/docs/tempo/latest/operations/consistent_hash_ring/) (e.g., distributor, ingester, metrics-generator, and compactor) will display web pages with the individual hash ring status, including the state, health, and last heartbeat time of each metrics-generator.

### Dependent Packages

When enabling `minio` for Tempo without filling in `loki.objectStorage` values, minioOperator is required as a minio tenant will be auto-created and configured as the object storage backend.

Tempo can be deployed by itself but since it's so closely tied with Grafana, the monitoring package is set as a required dependency within Big Bang so both are setup and auto-configured.

As mentioned above, Tempo requires a service mesh within the cluster to generate and track traces. Istio is set as a dependency for tempo as a result.
