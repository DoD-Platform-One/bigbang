# Nexus Integration with Prometheus

## Nexus Package Upgrades
If you are upgrading from versions prior to `42.0.0-bb.4` there are considerations to make for upgrade paths and inclusion of new values. In `42.0.0-bb.4` this package was updated to change the user for metrics collection `basicAuth` from `admin` to a `metrics` user. This was in an effort to reduce the permissions of the user with credentials stored in kubernetes.

### Big Bang Default
By default, Installation of Nexus Repository Manager through the Big Bang chart will result in `.Values.monitoring.serviceMonitor.createMetricsUser` being set to `true`. If this is a new installation of Nexus through Big Bang, it will run the job to establish the metrics user in Nexus required for the service monitor authentication. It is recommended that after initial installation, that `.Values.monitoring.serviceMonitor.createMetricsUser` and `.Values.secret.enabled` be set to `false`. This will prevent the job from running again, as well as remove the Nexus admin credentials from kubernetes.

If you are performing an upgrade of Big Bang with Nexus currently deployed, This job will likely fail until you add an override to nexus through `.Values.custom_admin_password` set to your current admin password. The job should then function as intended and then the recommendations for setting `.Values.monitoring.serviceMonitor.createMetricsUser` and `.Values.secret.enabled` be set to `false` still apply. 

Updating values in Big Bang after installation would look like:
```
addons:
  nexus:
    enabled: true
    values:
      secret:
        enabled: false
      monitoring:
        serviceMonitor:
          createMetricsUser: false
```

### Package Installation 
The recommended process for new installations of this package include:
- set `.Values.monitoring.serviceMonitor.createMetricsUser` to `true`
- set `.Values.secret.enabled` to `true`
- reconcile the package and ensure the target in prometheus for nexus is `UP`
- set `.Values.monitoring.serviceMonitor.createMetricsUser` to `false`
- set `.Values.secret.enabled` to `false`
  - This will remove the admin credentials secret from persisting in the cluster.

### Package Upgrade
The recommended process for upgrading an existing installation include:
- set `.Values.monitoring.serviceMonitor.createMetricsUser` to `true`
- set `.Values.secret.enabled` to `true`
- set `.Values.custom_admin_password` to your current admin password
- set `.Values.monitoring.serviceMonitor.createMetricsUser` to `false`
- set `.Values.secret.enabled` to `false`
  - This will remove the admin credentials secret from persisting in the cluster.
