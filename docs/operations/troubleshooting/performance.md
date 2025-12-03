# Performance Troubleshooting

This guide helps you diagnose and resolve performance issues in your Big Bang deployment. Performance problems can manifest in various ways including slow response times, high resource utilization, or application timeouts.

## Identifying Performance Issues

### 1. Review Monitoring Dashboards

Start by examining your observability stack:

- **Grafana Dashboards**: Check Big Bang's built-in dashboards for system metrics
  - Cluster overview dashboards for CPU, memory, and network usage
  - Application-specific dashboards for service performance
  - Node-level metrics for infrastructure health

- **Prometheus Metrics**: Query specific metrics to identify bottlenecks
  - Use the Prometheus UI to explore available metrics
  - Check the `kubernetes-service-endpoints` and `kubernetes-pods` targets for application metrics

### 2. Common Performance Indicators

Look for these warning signs:

- High CPU or memory utilization (>80% sustained)
- Increased response times in application logs
- Pod restarts due to resource limits
- Network latency or packet loss
- Storage I/O bottlenecks

## Resource Optimization

### 1. Adjusting Pod Resources

Edit deployment resource specifications:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

**Best Practices:**
- Set requests based on actual usage patterns
- Use limits to prevent resource starvation
- Monitor resource utilization over time before adjusting

### 2. Horizontal Pod Autoscaling (HPA)

Configure HPA to automatically scale pods based on metrics:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### 3. Vertical Pod Autoscaling (VPA)

Use VPA for automatic resource recommendations:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: myapp-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  updatePolicy:
    updateMode: "Auto"
```

## Infrastructure Optimization

### 1. Node Pool Management

Consider node pool adjustments:

- **Instance Types**: Use compute-optimized instances for CPU-intensive workloads
- **Storage**: Choose appropriate storage classes (SSD vs HDD)
- **Network**: Ensure adequate network bandwidth between nodes

### 2. Pod Placement

Optimize pod scheduling:

```yaml
# Node affinity for performance-critical workloads
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-type
          operator: In
          values: ["high-performance"]

# Anti-affinity to spread pods across nodes
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    podAffinityTerm:
      labelSelector:
        matchLabels:
          app: myapp
      topologyKey: kubernetes.io/hostname
```

### 3. Resource Quotas and Limits

Set namespace-level resource management:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: namespace-quota
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
```

## Application-Level Optimizations

### 1. Connection Pooling

Configure appropriate connection limits:

- Database connection pools
- HTTP client timeouts
- Keep-alive settings

### 2. Caching Strategies

Implement caching where appropriate:

- Redis for session storage
- CDN for static content
- Application-level caching

### 3. Database Performance

Optimize database interactions:

- Index optimization
- Query performance tuning
- Connection pooling
- Read replicas for read-heavy workloads

## Network Performance

### 1. Service Mesh Optimization

If using Istio:

- Configure appropriate circuit breakers
- Optimize retry policies
- Use traffic splitting for gradual deployments

### 2. Load Balancing

Ensure proper load distribution:

- Configure service load balancing algorithms
- Use ingress controllers efficiently
- Consider geographic traffic routing

## Monitoring and Alerting

### 1. Set Up Performance Alerts

Create alerts for key metrics:

```yaml
# Example Prometheus alert rule
groups:
- name: performance.rules
  rules:
  - alert: HighCPUUsage
    expr: container_cpu_usage_seconds_total > 0.8
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage detected"
```

### 2. Custom Metrics

Implement application-specific monitoring as described in the [monitoring guide](../monitoring.md):

- Add Prometheus annotations to services
- Enable global endpoint metrics if needed
- Create custom dashboards for your applications

## Performance Testing

### 1. Load Testing

Regular performance validation:

- Use tools like k6, JMeter, or Artillery
- Test under realistic load conditions
- Establish performance baselines

### 2. Chaos Engineering

Implement fault injection testing:

- Use tools like Chaos Monkey or Litmus
- Test system resilience under stress
- Validate auto-scaling behavior

## Common Performance Bottlenecks

### 1. CPU Throttling

**Symptoms**: Slow response times despite low CPU usage
**Solutions**: 
- Increase CPU limits
- Optimize application code
- Use CPU profiling tools

### 2. Memory Pressure

**Symptoms**: Pod restarts, OOM kills
**Solutions**:
- Increase memory limits
- Optimize memory usage patterns
- Implement garbage collection tuning

### 3. I/O Bottlenecks

**Symptoms**: High disk wait times
**Solutions**:
- Use faster storage classes
- Optimize database queries
- Implement read caching

### 4. Network Latency

**Symptoms**: Slow inter-service communication
**Solutions**:
- Optimize service mesh configuration
- Use connection pooling
- Consider service colocation

## Next Steps

If performance issues persist:

1. Review [monitoring documentation](../monitoring.md) for advanced observability setup
2. Check [networking troubleshooting](networking.md) for network-related issues
3. Consider engaging with the Big Bang community for complex performance challenges
4. Plan capacity upgrades if current infrastructure is insufficient

Remember to always test performance changes in a non-production environment first and monitor the impact of optimizations over time.
