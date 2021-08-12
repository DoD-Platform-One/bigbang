# Goals of this Diagram

* Help new users understand the data flow of prometheus metrics

## Prometheus Metrics Data Flow Diagram

![metrics_data_flow_diagram.app.diagrams.net.png](images/metrics_data_flow_diagram.app.diagrams.net.png)

| Line Number | Protocol | Port | Description |
| --- |  --- | --- | --- |
| N1 | HTTP | varies* | *A standard port number for prometheus metric endpoint URLs doesn't exist. The Prometheus Operator is able to use ServiceMonitors and Kubernetes Services to automatically discover IP addresses of pods and these varying prometheus metric endpoint ports. Once a minute the prometheus Operator dynamically regenerates a metric collection config file that the Prometheus Server continuously uses to collect metrics. In the majority of cases prometheus metric endpoints, are read over HTTP, and are only reachable over the Kubernetes Inner Cluster Network.  |
