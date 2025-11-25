# Backup and Restore

[[_TOC_]]

## Gitlab Backups and Restores

### Gitlab Helm Chart Configuration

1. Follow the `Backup and rename gitlab-rails-secret` task within the [Production document](../configuration/sample-prod-config.md).
1. Fill in our externalStorage values, specifically `addons.gitlab.objectStorage.iamProfile` or both `.Values.addons.gitlab.objectStorage.accessKey` & `.Values.addons.gitlab.objectStorage.accessSecret` along with `.Values.addons.gitlab.objectStorage.bucketPrefix` or you can override in the name for your own bucket eg:
```yaml
addons:
  gitlab:
    values:
      global:
       appConfig:
         backups:
           bucket: "BUCKET_NAME"
```
* If you would like to perform manual backups, you will need to ensure the `tmp` location in the toolbox pod has a PVC attached:
```yaml
addons:
  gitlab:
    values:
      gitlab:
        toolbox:
          persistence:
            enabled: true
            size: 100Gi 
```

### Backing up Gitlab

#### Manual Steps

To perform a manual complete backup of Gitlab, exec into your Gitlab Toolbox pod and run the following:
  1. Find your Gitlab Toolbox pod.
     ```shell
     kubectl get pods -l release=gitlab,app=toolbox -n gitlab
     kubectl exec -it gitlab-toolbox-XXXXXXXXX-XXXXX -n gitlab -- /bin/sh
     ```
  1. Execute the backup-utility command which will pull down data from the database, gitaly, and other portions of the ecosystem. Tar them up and push to your configured cloud storage.
     ```shell
     backup-utility --skip registry,lfs,artifacts,packages,uploads,pseudonymizer,terraformState,backups
     ```

You can read more on the upstream documentation: https://docs.gitlab.com/charts/backup-restore/backup.html#create-the-backup.

#### Automatic Cron-based Backups

It is recommended to set up automatic backups via Gitlab toolbox's cron settings:
```yaml
addons:
  gitlab:
    values:
      gitlab:
        toolbox:
          backups:
            cron:
              enabled: true
              extraArgs: "--skip registry,lfs,artifacts,packages,uploads,pseudonymizer,terraformState,backups"
              persistence:
                enabled: true
                size: '200Gi'
              resources:
                limits:
                  cpu: 800m
                  memory: "2Gi"
                requests:
                  cpu: 800m
                  memory: "2Gi" 
```
You can read more on the upstream documentation: https://docs.gitlab.com/charts/charts/gitlab/toolbox/#configuration

### Restore Gitlab

1. Ensure your gitlab-rails secret is present in gitops or in-cluster and it correctly matches the database to which the chart is pointed.
   * If you need to replace or update your rails secret, once it is updated be sure to restart the following pods:
     ```shell
     kubectl rollout -n gitlab restart deploy/gitlab-sidekiq-all-in-1-v2
     kubectl rollout -n gitlab restart deploy/gitlab-webservice-default
     kubectl rollout -n gitlab restart deploy/gitlab-toolbox
     ```
2. Exec into the toolbox pod and run the backup-utility command:
   1. find your Gitlab Toolbox pod. 
     ```shell
     kubectl get pods -l release=gitlab,app=toolbox -n gitlab
     kubectl exec -it gitlab-toolbox-XXXXXXXXX-XXXXX -n gitlab -- /bin/sh
     ```
   * Find your most recent backup from cloud storage by finding the last line of your most recent backup job pod:
      ```shell
      kubectl get po -l release=gitlab,job-name -n gitlab --sort-by=.metadata.creationTimestamp
      kubectl logs gitlab-toolbox-backup-XXXXXXXX-XXXXX -n gitlab
      ```
   * Find your most recent backup via AWS CLI:
      ```shell
      aws s3api list-objects --bucket gitlab-backups --query 'reverse(sort_by(Contents,&LastModified))[0].Key' --output 
      # Save the output, it is in the format TIMESTAMP_VALUE.tar
      ```
   2. Execute the backup-utility command which will pull down the tarred data from your configured cloud storage and restore.
     ```shell
     # Using the filename
     backup-utility --restore -f s3://BUCKET_NAME/ARCHIVE_NAME.tar
     # Using the Timestamp
     backup-utility --restore -t TIMESTAMP_VALUE
     ```
You can read more on the upstream documentation: https://docs.gitlab.com/charts/backup-restore/restore.html#restoring-the-backup-file.

<!-- TODO: move this to migration -->
## Migrating a Nexus Repository Using Velero

This guide demonstrates how to perform a migration of Nexus repositories and artifacts between Kubernetes clusters.

### Prerequisites/Assumptions

* K8s running in AWS
* Nexus PersistentVolume is using AWS EBS
* Migration is between clusters on the same AWS instance and availability zone (due to known Velero [limitations](https://velero.io/docs/v1.6/locations/#limitations--caveats))
* Migration occurs between K8s clusters with the same version
* Velero CLI [tool](https://github.com/vmware-tanzu/velero/releases)
* Crane CLI [tool](https://github.com/google/go-containerregistry)

### Preparation

1. Ensure the Velero addon in the Big Bang values file is properly configured. Sample configuration is provided in the following:

    ```yaml
    addons:
      velero:
        enabled: true
        plugins:
        - aws
        values:
          serviceAccount:
            server:
              name: velero
          configuration:
            provider: aws
            backupStorageLocation:
              bucket: nexus-velero-backup
            volumeSnapshotLocation:
              provider: aws
              config:
                region: us-east-1
          credentials:
            useSecret: true
            secretContents:
              cloud: |
                [default]
                aws_access_key_id = <CHANGE ME>
                aws_secret_access_key = <CHANGE ME>
    ```

1. Manually create an S3 bucket that the backup configuration will be stored in (in this case it is named `nexus-velero-backup`), this should match the `configuration.backupStorageLocation.bucket` key above.
1. The `credentials.secretContents.cloud` credentials should have the necessary permissions to read/write to S3, volumes and volume snapshots.
1. As a sanity check, take a look at the Velero logs to make sure the backup location (S3 bucket) is valid, you should see something similar to the following:

    ```plaintext
    level=info msg="Backup storage location valid, marking as available" backup-storage-location=default controller=backup-storage-location logSource="pkg/controller/backup_storage_location_controller.go:121"
    ```

1. Ensure there are images/artifacts in Nexus. An as example we will use the [Doom DOS image](https://earthly.dev/blog/dos-gaming-in-docker/) and a simple nginx image. Running `crane catalog nexus-docker.bigbang.dev` will show all of the artifacts and images in Nexus:  

    ```console
    repository/nexus-docker/doom-dos
    repository/nexus-docker/nginx
    ```

### Backing Up Nexus

In the cluster containing the Nexus repositories to migrate, running the following command will create a backup called `nexus-ns-backup` and will backup all resources in the `nexus-repository-manager` namespace, including the associated PersistentVolume:

```shell
velero backup create nexus-ns-backup --include-namespaces nexus-repository-manager --include-cluster-resources=true
```

Specifically, this will backup all Nexus resources to the S3 bucket `configuration.backupStorageLocation.bucket` specified above and will create a volume snapshot of the Nexus EBS volume.

 **Double-check** AWS to make sure this is the case by reviewing the contents of the S3 bucket:

 ```shell
 aws s3 ls s3://nexus-velero-backup --recursive --human-readable --summarize
 ```

Expected output:  

```console
backups/nexus-ns-backup/nexus-ns-backup-csi-volumesnapshotcontents.json.gz
backups/nexus-ns-backup/nexus-ns-backup-csi-volumesnapshots.json.gz
backups/nexus-ns-backup/nexus-ns-backup-logs.gz
backups/nexus-ns-backup/nexus-ns-backup-podvolumebackups.json.gz
backups/nexus-ns-backup/nexus-ns-backup-resource-list.json.gz
backups/nexus-ns-backup/nexus-ns-backup-volumesnapshots.json.gz
backups/nexus-ns-backup/nexus-ns-backup.tar.gz
backups/nexus-ns-backup/velero-backup.json
```

Also ensure an EBS volume snapshot has been created and the Snapshot status is `Completed`.  
![volume-snapshot](https://repo1.dso.mil/big-bang/product/bb-static/-/raw/main/docs/assets/imgs/guides/volume-snapshot.png)

### Restoring From Backup

1. In the new cluster, ensure that Nexus and Velero are running and healthy.
    - It is critical to ensure that Nexus has been included in the new cluster's Big Bang deployment, otherwise the restored Nexus configuration will not be managed by the Big Bang Helm chart.
1. If you are using the same `velero.values` from above, Velero should automatically be configured to use the same backup location as before. Verify this with `velero backup get` and you should see output that looks similar to the following:

    ```console
    NAME              STATUS      ERRORS   WARNINGS   CREATED                         EXPIRES   STORAGE LOCATION   SELECTOR
    nexus-ns-backup   Completed   0        0          2022-02-08 12:34:46 +0100 CET   29d       default            <none>
    ```  

1. To perform the migration, Nexus must be shut down. In the Nexus Deployment, bring the `spec.replicas` down to `0`.
1. Ensure that the Nexus PVC and PV are also removed (**you may have to delete these manually!**), and that the corresponding Nexus EBS volume has been deleted.
    - If you have to remove the Nexus PV and PVC manually, delete the PVC first, which should cascade to the PV. Then, manually delete the underlying EBS volume (if it still exists).

1. Now that Nexus is down and the new cluster is configured to use the same backup location as the old one, perform the migration by running:  
    `velero restore create --from-backup  nexus-ns-backup`

1. The Nexus PV and PVC should be recreated (**NOTE:** verify this before continuing!), but the pod will fail to start due to the previous change in the Nexus deployment spec. Change the Nexus deployment `spec.replicas` back to `1`. This will bring up the Nexus pod which should connect to the PVC and PV created during the Velero restore.

1. Once the Nexus pod is running and healthy, log in to Nexus and verify that the repositories have been restored.
    - The credentials to log in will have been restored from the Nexus backup, so they should match the credentials of the Nexus that was migrated (not the new installation!).
    - It is recommended to log in to Nexus and download a sampling of images/artifacts to ensure they are working as expected.

    For example, login to Nexus using the migrated credentials:  
    `docker login -u admin -p admin nexus-docker.bigbang.dev/repository/nexus-docker`

    Running `crane catalog nexus-docker.bigbang.dev` should show the same output as before:

    ```console
    repository/nexus-docker/doom-dos
    repository/nexus-docker/nginx
    ```

    To ensure the integrity of the migrated image, we will pull and run the `doom-dos` image and defeat evil!  

    ```shell
    docker pull nexus-docker.bigbang.dev/repository/nexus-docker/doom-dos:latest && \
    docker run -p 8000:8000 nexus-docker.bigbang.dev/repository/nexus-docker/doom-dos:latest
    ```

    ![doom](https://repo1.dso.mil/big-bang/product/bb-static/-/raw/main/docs/assets/imgs/guides/doom.png "doom")

### Appendix

#### Sample Nexus values

```yaml
addons:
  nexusRepositoryManager:
    enabled: true
    values:
      nexus:
        docker:
          enabled: true
          registries:
            - host: nexus-docker.bigbang.dev
              port: 5000
```

<!-- TODO: link to or add velero restore docs -->
