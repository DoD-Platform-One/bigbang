# Installing and Configuring Vertical Pod Autoscaler (VPA) for Vertical Scaling of Fluent Bit and Promtail Pods

Since log forwarder pods, like Fluentbit and Promtail, are designed to have one pod per node via a ReplicaSet instantiation, they are unable to be horizontally scaled when reaching their resource limits. They can still be vertically scaled once [VPA](https://repo1.dso.mil/big-bang/product/packages/vpa) is installed.

# 1. Prerequisites

- Kubernetes cluster must be running version 1.14 or later.
- Kubectl command-line tool must be configured to access the cluster.

# 2. Install the Vertical Pod Autoscaler
  1. Run the following commands to install the VPA components from the package repo:

    
    git clone https://repo1.dso.mil/big-bang/product/packages/vpa.git
    cd vpa
    helm install vertical-pod-autoscaler chart/
    
  2. Add package via the Big Bang 2.0 `packages:` key:
    
    packages:
      vpa:
        enabled: true
        git:
          repo: "https://repo1.dso.mil/big-bang/product/packages/vpa.git"
          tag: LATEST_TAG
          path: chart
        ...
    

# 3.Configure Fluent Bit Deployment
For Fluentbit, make sure the following settings are added to the packages Helm Chart [values.yaml](https://repo1.dso.mil/big-bang/product/packages/fluentbit/-/blob/main/chart/values.yaml_) file:

```yaml
autoscaling:
  vpa:
    enabled: true
    annotations: {}
    # List of resources that the vertical pod autoscaler can control. Defaults to cpu and memory
    controlledResources: []
    # Define the max allowed resources for the pod
    maxAllowed:
      cpu: 200m
      memory: 100Mi
    # Define the min allowed resources for the pod
    minAllowed:
      cpu: 200m
      memory: 100Mi
```

# 4.Configure Promtail Deployment

For Promtail, make sure the following settings are added to the Packages Helm Chart [values.yaml](https://repo1.dso.mil/big-bang/product/packages/promtail/-/blob/main/chart/values.yaml) file:

```yaml
# -- config for VerticalPodAutoscaler
vpa:
  enabled: true
  # kind -- DaemonSet or Deployment
  kind: DaemonSet
  annotations: {}
  # List of resources that the vertical pod autoscaler can control. Defaults to cpu and memory
  controlledResources: []
  # Define the max allowed resources for the pod
  maxAllowed:
    cpu: 200m
    memory: 100Mi
  # Define the min allowed resources for the pod
  minAllowed:
    cpu: 200m
    memory: 100Mi
  updatePolicy:
    # Specifies whether recommended updates are applied when a Pod is started and whether recommended updates
    # are applied during the life of a Pod. Possible values are "Off", "Initial", "Recreate", and "Auto".
    updateMode: Auto
```

# 5.Verify VPA Status

Check the VPA status to ensure it is functioning correctly and providing recommendations.

Run the following command:

```shell
    kubectl describe vpa -A 
```

Look for the Conditions section and verify that the status is Healthy.

# 6.Monitor and Observe Scaling

Monitor the cluster and observe how the VPA scales the Fluent Bit and Promtail pods based on resource utilization. Review the pod resource utilization metrics using commands like kubectl top pods or monitoring tools like Prometheus and Grafana.

By following these steps, you should be able to install and configure the VPA to vertically scale Fluent Bit and Promtail pods in your Kubernetes cluster when additional resources are needed and headroom is available. Adjust the configurations and policies based on your specific requirements and application characteristics.
