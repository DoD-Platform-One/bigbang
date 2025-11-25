# Networking Troubleshooting

This guide helps you diagnose and resolve networking issues in your Big Bang deployment. Network problems can manifest as connection timeouts, permission denials, DNS resolution failures, and service mesh configuration issues.

## Overview

Big Bang networking involves multiple layers that can cause connectivity issues:

- **Network Policies**: Kubernetes network policies that control pod-to-pod communication
- **Istio Service Mesh**: mTLS, authorization policies, traffic routing, and ingress
- **DNS Resolution**: Service discovery and external DNS lookups
- **Load Balancing**: Ingress controllers and service load balancing
- **Cluster Networking**: CNI plugin configuration and node networking

## Common Network Issue Symptoms

### 1. Connection Reset (ECONNRESET)

**Symptom**: Connections are immediately reset or refused
**Common Causes**:
- Network policies blocking traffic
- Missing service endpoints
- Port misconfigurations

**Example Error**:
```
Error: connect ECONNRESET 10.0.0.1:8080
```

### 2. HTTP 403 RBAC Access Denied

**Symptom**: HTTP 403 responses with RBAC denial message
**Common Causes**:
- Istio authorization policies blocking requests
- Missing service account permissions
- Incorrect JWT tokens or certificates

**Example Error**:
```
HTTP 403 Forbidden
RBAC: access denied
```

### 3. DNS Resolution Failures

**Symptom**: Cannot resolve service names
**Common Causes**:
- CoreDNS configuration issues
- Network policies blocking DNS traffic
- Service discovery problems

**Example Error**:
```
nslookup: can't resolve 'service-name.namespace.svc.cluster.local'
```

### 4. TLS/mTLS Errors

**Symptom**: Certificate validation failures
**Common Causes**:
- Istio mTLS configuration issues
- Certificate expiration or misconfiguration
- CA bundle problems

**Example Error**:
```
x509: certificate signed by unknown authority
```

## Quick Network Diagnostics

### 1. Basic Connectivity Test

Use a debug pod to test network connectivity:

```bash
# Create debug pod
kubectl run debug-pod --image=nicolaka/netshoot -it --rm -- bash

# Inside the debug pod:
# Test DNS resolution
nslookup <service-name>.<namespace>.svc.cluster.local

# Test port connectivity
nc -zv <service-name>.<namespace>.svc.cluster.local <port>

# Test HTTP connectivity
curl -v http://<service-name>.<namespace>.svc.cluster.local:<port>

# Test with specific source namespace
kubectl run debug-pod --image=nicolaka/netshoot -it --rm -n <source-namespace> -- bash
```

### 2. Check Service and Endpoints

Verify services are properly configured:

```bash
# Check service configuration
kubectl get svc -n <namespace>
kubectl describe svc <service-name> -n <namespace>

# Check service endpoints
kubectl get endpoints <service-name> -n <namespace>
kubectl describe endpoints <service-name> -n <namespace>

# Verify pod labels match service selectors
kubectl get pods --show-labels -n <namespace>
```

### 3. Review Network Events

Check for networking-related events:

```bash
# Get recent events
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | grep -i "network\|connection\|dns"

# Check specific namespace events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

## Network Policy Troubleshooting

### 1. Identify Network Policy Blocks

Check if network policies are blocking traffic:

```bash
# List network policies
kubectl get networkpolicy -A

# Describe specific policy
kubectl describe networkpolicy <policy-name> -n <namespace>

# Check policy logs (if supported by CNI)
kubectl logs -n kube-system -l app=calico-node  # For Calico
```

### 2. Test Network Policy Rules

Use debug pods to test connectivity:

```bash
# Test from different namespaces
kubectl run test-source --image=nicolaka/netshoot -it --rm -n <source-namespace> -- nc -zv <target-service> <port>

# Test with specific labels
kubectl run test-pod --image=nicolaka/netshoot --labels="app=test" -it --rm -- nc -zv <target-service> <port>
```

### 3. Common Network Policy Issues

**Default Deny All**:
```yaml
# Check for restrictive default policies (these should be there, but may block traffic if other rules are missing)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

**Missing Egress Rules**:
```yaml
# Allow DNS egress (common requirement)
spec:
  egress:
  - to: []
    ports:
    - protocol: UDP
      port: 53
```

### 4. Network Policy Remediation

Create temporary allow-all policy for testing:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-test
  namespace: <namespace>
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - {}
  egress:
  - {}
```

## Istio Service Mesh Troubleshooting

### 1. Check Istio Configuration

Verify Istio setup and sidecar injection:

```bash
# Check Istio pods
kubectl get pods -n istio-system

# Verify sidecar injection
kubectl get pods -n <namespace> -o jsonpath='{.items[*].spec.containers[*].name}'

# Check injection labels
kubectl get namespace <namespace> --show-labels
```

### 2. Authorization Policy Issues

Diagnose authorization policy blocks:

```bash
# List authorization policies
kubectl get authorizationpolicy -A

# Describe specific policy
kubectl describe authorizationpolicy <policy-name> -n <namespace>

# Check Envoy access logs
kubectl logs <pod-name> -n <namespace> -c istio-proxy | grep -i "rbac\|denied"
```

### 3. Use Kiali for Service Mesh Debugging

Access Kiali dashboard to visualize traffic flow:

Open browser to kiali dashboard (likely at `https://kiali.<your-domain>`)

Check:
- Service topology
- Traffic flow patterns
- Error rates and response codes
- mTLS status indicators

**Kiali Debugging Features**:
- **Graph View**: Visualize service communications and identify blocked connections
- **Applications View**: Check application health and configuration
- **Workloads View**: Review deployment and pod status
- **Services View**: Examine service configurations
- **Istio Config**: Validate Istio resource configurations

### 4. mTLS Configuration Issues

Debug mutual TLS problems:

```bash
# Check PeerAuthentication policies
kubectl get peerauthentication -A

# Check DestinationRules
kubectl get destinationrule -A

# Test mTLS connectivity
istioctl proxy-config cluster <pod-name>.<namespace> | grep <target-service>

# Check certificate status
istioctl proxy-config secret <pod-name>.<namespace>
```

### 5. Virtual Service and Gateway Issues

Debug traffic routing problems:

```bash
# Check VirtualServices
kubectl get virtualservice -A
kubectl describe virtualservice <vs-name> -n <namespace>

# Check Gateways
kubectl get gateway -A
kubectl describe gateway <gateway-name> -n <namespace>

# Check ingress gateway logs
kubectl logs -n istio-system -l app=istio-proxy
```

## DNS Resolution Issues

### 1. CoreDNS Troubleshooting

Check DNS service health:

```bash
# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# Check CoreDNS configuration
kubectl get configmap coredns -n kube-system -o yaml
```

### 2. DNS Resolution Testing

Test DNS from pods:

```bash
# Test internal service resolution
kubectl exec -it <pod-name> -n <namespace> -- nslookup <service-name>.<namespace>.svc.cluster.local

# Test external DNS resolution
kubectl exec -it <pod-name> -n <namespace> -- nslookup google.com

# Check DNS configuration in pod
kubectl exec -it <pod-name> -n <namespace> -- cat /etc/resolv.conf
```

### 3. External DNS Issues

For external service access:

```bash
# Check ServiceEntry configurations
kubectl get serviceentry -A

# Test external connectivity
kubectl run test-external --image=nicolaka/netshoot -it --rm -- curl -v https://external-service.com
```

## General Network Debugging

### 1. Pod-to-Pod Connectivity

Test direct pod communication:

```bash
# Get pod IPs
kubectl get pods -o wide -n <namespace>

# Test direct IP connectivity
kubectl exec -it <source-pod> -n <namespace> -- ping <target-pod-ip>

# Test port connectivity
kubectl exec -it <source-pod> -n <namespace> -- nc -zv <target-pod-ip> <port>
```

### 2. Node-Level Networking

Check node network configuration:

```bash
# Check node status
kubectl get nodes -o wide

# Check node network interfaces
kubectl debug node/<node-name> -it --image=nicolaka/netshoot

# In the debug container:
ip addr show
ip route show
iptables -L -n
```

### 3. CNI Plugin Issues

Debug CNI-specific problems:

```bash
# For Calico
kubectl get pods -n kube-system -l k8s-app=calico-node
kubectl logs -n kube-system -l k8s-app=calico-node

# For Cilium
kubectl get pods -n kube-system -l k8s-app=cilium
kubectl logs -n kube-system -l k8s-app=cilium

# Check CNI configuration
ls -la /etc/cni/net.d/
cat /etc/cni/net.d/*.conf
```

## Load Balancer and Ingress Issues

### 1. Ingress Controller Debugging

Check ingress configuration:

```bash
# Check ingress resources
kubectl get ingress -A
kubectl describe ingress <ingress-name> -n <namespace>

# Check ingress controller logs
kubectl logs -n istio-system -l app=istio-proxy  # For Istio ingress
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx  # For NGINX ingress
```

### 2. Load Balancer Service Issues

Debug LoadBalancer services:

```bash
# Check service status
kubectl get svc -A --field-selector spec.type=LoadBalancer

# Check cloud provider integration
kubectl describe svc <service-name> -n <namespace>

# Check load balancer logs (cloud provider specific)
```

## Performance and Latency Issues

### 1. Network Latency Testing

Measure network performance:

```bash
# Test latency between pods
kubectl exec -it <source-pod> -n <namespace> -- ping -c 10 <target-service>

# Test bandwidth
kubectl run iperf-server --image=networkstatic/iperf3 -n <namespace> -- iperf3 -s
kubectl run iperf-client --image=networkstatic/iperf3 -it --rm -- iperf3 -c <server-ip>
```

### 2. Service Mesh Performance

Monitor service mesh overhead:

```bash
# Check Envoy proxy resource usage
kubectl top pods -n <namespace>

# Review proxy configuration
istioctl proxy-config cluster <pod-name>.<namespace>
istioctl proxy-config listener <pod-name>.<namespace>
```

## Common Remediation Patterns

### 1. Temporary Network Policy Override

**DEV ONLY FOR DEBUGGING**:

Create permissive policy for debugging:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: debug-allow-all
  namespace: <namespace>
spec:
  podSelector:
    matchLabels:
      app: <app-name>
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - {}
  egress:
  - {}
```

### 2. Authorization Policy Bypass

**DEV ONLY FOR DEBUGGING**:

Create permissive authorization policy:

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: debug-allow-all
  namespace: <namespace>
spec:
  selector:
    matchLabels:
      app: <app-name>
  rules:
  - {}
```

### 3. DNS Troubleshooting Steps

1. **Check pod DNS configuration**:
   ```bash
   kubectl exec -it <pod> -- cat /etc/resolv.conf
   ```

2. **Test internal DNS**:
   ```bash
   kubectl exec -it <pod> -- nslookup kubernetes.default.svc.cluster.local
   ```

3. **Test external DNS**:
   ```bash
   kubectl exec -it <pod> -- nslookup google.com
   ```

4. **Check CoreDNS**:
   ```bash
   kubectl get pods -n kube-system -l k8s-app=kube-dns
   kubectl logs -n kube-system -l k8s-app=kube-dns
   ```

## Monitoring and Alerting

### 1. Network Metrics

Monitor key network metrics as described in the [monitoring guide](../monitoring.md):

- Connection success/failure rates
- DNS query success rates
- Service mesh request latency
- Network policy deny rates

### 2. Set Up Network Alerts

Create alerts for network issues:

```yaml
# Example Prometheus alert rules
groups:
- name: network.rules
  rules:
  - alert: HighConnectionFailures
    expr: rate(failed_connections_total[5m]) > 0.1
    for: 2m
    annotations:
      summary: "High connection failure rate detected"
```

## Next Steps

If networking issues persist:

1. Review [package troubleshooting](packages.md) for application-specific network problems
2. Check [performance troubleshooting](performance.md) for network performance optimization
3. Engage with the Big Bang community for complex networking scenarios
4. Consider involving cloud provider support for infrastructure-level networking issues

Remember to always test network changes in a non-production environment first and document any custom network configurations for future reference.
