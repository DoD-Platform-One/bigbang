# Scrape Annotated Application Metrics

Big Bang's monitoring package can discover Prometheus metrics from annotated Services or Pods. Prefer a package-owned `ServiceMonitor` or `PodMonitor` when one is available; annotation discovery is useful for applications that do not provide those resources.

## Prerequisites

- The Big Bang monitoring package is enabled.
- The application exposes metrics in Prometheus format.
- The scrape path, port, and protocol are known.
- Network policies allow Prometheus to reach the target.

## Enable Annotation Discovery

Enable one or both discovery jobs in the Big Bang values supplied by the environment:

```yaml
monitoring:
  globalServiceEndpointMetrics:
    enabled: true
  globalPodEndpointMetrics:
    enabled: true
```

These values render the `kubernetes-service-endpoints` and `kubernetes-pods` scrape jobs respectively. They are disabled by default.

## Annotate a Service

Add annotations to the application's Service. Substitute the actual named or numeric metrics port and path:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-application
  namespace: my-application
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
spec:
  ports:
    - name: metrics
      port: 8080
      targetPort: metrics
  selector:
    app.kubernetes.io/name: my-application
```

Do not enable annotation discovery and a `ServiceMonitor` for the same endpoint unless duplicate ingestion is intentional.

## Verify the Target

After Flux reconciles the configuration:

1. Open the Prometheus Targets page.
2. Find the target under `kubernetes-service-endpoints` or `kubernetes-pods`.
3. If it is absent, inspect Prometheus service discovery and confirm the annotations and selectors.
4. If it is present but down, verify the port, path, protocol, TLS settings, and applicable network policies.

For package-specific dashboards, alerts, and `ServiceMonitor` settings, use the documentation for that package and the [monitoring package](../packages/core/monitoring.md).
