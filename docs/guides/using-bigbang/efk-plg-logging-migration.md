# Switching Between EFK and PLG

These instructions detail how to switch between EFK and PLG logging solutions.

The EFK stack is an open-source choice for the Kubernetes log aggregation and analysis and is comprised of the following:
- Elasticsearch is a distributed and scalable search engine commonly used to sift through large volumes of log data.
- Fluentbit is a log shipper. It is an open source log collection agent which support multiple data sources and output formats.
- Kibana is a UI tool for querying, data visualization and dashboards.

Today the EFK stack (Elasticsearch, Fluentbit, and Kibana) is enabled by default in the bigbang chart.
The EFK stack appears within the chart as follows:

```yaml

elasticsearchKibana:
  # -- Toggle deployment of Logging (Elastic/Kibana).
  enabled: true

eckOperator:
  # -- Toggle deployment of ECK Operator.
  enabled: true

fluentbit:
  # -- Toggle deployment of Fluent-Bit.
  enabled: true

```

If you want to use a logging solution that doesn't require a license and has a smaller footprint, Big Bang provides PLG. PLG is comprised of:
- Promtail is an agent that detects targets (e.g., local log files), attaches labels to log streams from the pods, and ships them to Loki.
- Loki is an open-source, multi-tenant log aggregation system. It can be used with Grafana and Promtail to collect and access logs.
- Grafana is an open-source visualization platform that processes time-series data from Loki and makes the logs accessible in a web UI.

Currently, the way to switch from the default EFK stack to PLG is to set the following values in the bigbang chart:

```yaml

elasticsearchKibana:
  # -- Toggle deployment of Logging (EFK).
  enabled: false // Disables the Elasticsearch Kibana deployment

eckOperator:
  # -- Toggle deployment of ECK Operator.
  enabled: false // Do not need the eck operator either

fluentbit:
  # -- Toggle deployment of Fluent-Bit.
  enabled: false // Disables Fluentbit

jaeger:
  # -- Toggle deployment of Jaeger.
  enabled: false // Disables Jaeger | Uses elasticsearch to persist searches, not required when elasticsearch is disabled

loki:
  # -- Toggle deployment of Loki.
  enabled: true // Deploys Loki | Logging injester and queryer replacing elasticsearch kibana

promtail:
  # -- Toggle deployment of Promtail.
  enabled: true // Deploys Promtail

tempo:
  # -- Toggle deployment of Tempo.
  enabled: true // Deploys Tempo | Tracing backend replacing jaeger

```

NOTE:
Both Fluentbit and Promtail forward logs to Grafana Loki. Should you want a logging stack comprised solely of Grafana technologies, the PLG stack will accommodate. The use of Fluentbit to send logs (log forwarder) is still a viable option rather than Promtail, and is configured within Big Bang to ship to Loki if enabled. Big Bang's recommendation is to use Fluentbit as a log forwarder because it is more feature rich. Promtail can only send to a limited set of endpoints (e.g., Loki and S3), whereas Fluentbit can send to numerous endpoints.
