# Big Bang Logging Stacks

This documentation details how to choose and enable a logging application stack for your Big Bang deployment. 

As of Big Bang 3.0, there are two primary logging stacks offered:

1. **ALG Stack (Default)** 
2. **EFK Stack**

## Available Logging Stacks

### ALG Stack (Default)

The ALG stack is the Grafana family consisting of:

- **Alloy**: A multi-purpose OpenTelemetry collector agent used to collect logs and forward them to Loki
- **Loki**: The main service responsible for storing logs and processing queries
- **Grafana**: A front-end web interface for querying and displaying logs

### EFK Stack

The EFK stack follows the Elastic family and Fluentbit consisting of:

- **Elasticsearch**: A distributed and scalable search engine commonly used to sift through large volumes of log data
- **Fluentbit**: A log shipper agent which supports multiple data sources and outp◊ut formats
- **Kibana**: A User Interface (UI) tool for querying, data visualization and dashboards

### Switching Logging Stacks

Switching between different logging stacks requires updating the enable/disable values for the desired applications in your values.yaml file.

#### Enabling EFK logging stack instead of ALG

```yaml
# Big Bang values.yaml
# Enable EFK stack
elasticsearchKibana:
  # -- Toggle deployment of Logging (Elastic/Kibana)
  enabled: true
eckOperator:
  # -- Toggle deployment of ECK Operator
  enabled: true
fluentbit:
  # -- Toggle deployment of Fluent-Bit
  enabled: true

# Disable ALG stack
alloy:
  # -- Toggle deployment of grafana alloy
  enabled: false
loki:
  # -- Toggle deployment of Loki
  enabled: false
grafana:
  # -- Toggle deployment of Grafana
  enabled: false
```

#### Alternative Configuration: Fluentbit with Loki

There may be use cases where teams want to run Fluentbit with Loki, often for lighter resource usage or system support. Big Bang automatically supports this configuration when fluentbit and loki are enabled.

```yaml
# Big Bang values.yaml
# Enabling Fluentbit with Loki
fluentbit:
  # -- Toggle deployment of Fluent-Bit
  enabled: true
loki:
  # -- Toggle deployment of Loki
  enabled: true
grafana:
  # -- Toggle deployment of Grafana
  enabled: true
```

### Additional Resources

For more detailed configuration options and advanced setup scenarios, refer to the complete Big Bang documentation.