# Appliance Mode

Big Bang Core currently provides the ability for all packages to be enabled and running Highly Available while being able to fit within the following footprint:
* 4 vCPU
* 16 GB Ram

There is a values.yaml file in this same directory which provides an example of some overrides for the core packages. Flux is also required and included as part of the resource consumption and allocation.

| Big Bang Core Package | Comments |
|-------|---|
| Flux | source, helm, kustomize & notification controllers |
| Istio | Possibly too heavy for reduced compute but still able to run on above machine |
| Jaeger | Not enough value to justify value and footprint above Tempo |
| Tempo | tracing capability integrated with grafana |
| Kiali | Not enough value to justify running in smaller footprint |
| Monitoring | Prometheus/Alertmanager/Grafana for monitoring/alerting |
| ECK | Too heavy for reduced compute |
| Loki/Promtail | need logging |
| Gatekeeper/Kyverno | Static environment on edge, compliance will be validated in development/cloud |
| Cluster Auditor/Kyerno Reporter | Static environment on edge, compliance will be validated in development/cloud |
| Twistlock/Neuvector | Runtime security at least |

Review and reference [the values file in the configs folder to deploy BigBang in Appliance Mode](../../assets/configs/appliance-mode/values.yaml).
