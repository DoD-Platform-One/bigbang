# Gitlab Backups and Restores

## Gitlab Helm Chart Configuration
1. Follow the `Backup and rename gitlab-rails-secret` task within the [Production document](../../understanding-bigbang/configuration/sample-prod-config.md).
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

## Backing up Gitlab

### Manual Steps
To perform a manual complete backup of Gitlab, exec into your Gitlab Toolbox pod and run the following:
  1. find your Gitlab Toolbox pod 
     ```shell
     kubectl get pods -l release=gitlab,app=toolbox -n gitlab
     kubectl exec -it gitlab-toolbox-XXXXXXXXX-XXXXX -n gitlab -- /bin/sh
     ```
  1. Execute the backup-utility command which will pull down data from the database, gitaly, and other portions of the ecosystem, tar them up and push to your configured cloud storage.
     ```shell
     backup-utility --skip registry,lfs,artifacts,packages,uploads,pseudonymizer,terraformState,backups
     ```

You can read more on the upstream documentation: https://docs.gitlab.com/charts/backup-restore/backup.html#create-the-backup

### Automatic Cron-based Backups
It is recommended to setup automatic backups via Gitlab toolbox's cron settings:
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

## Restore Gitlab
1. Ensure your gitlab-rails secret is present in gitops or in-cluster and it correctly matches the database to which the chart is pointed.
   * If you need to replace or update your rails secret, once it is updated be sure to restart the following pods:
     ```shell
     kubectl rollout -n gitlab restart deploy/gitlab-sidekiq-all-in-1-v2
     kubectl rollout -n gitlab restart deploy/gitlab-webservice-default
     kubectl rollout -n gitlab restart deploy/gitlab-toolbox
     ```
2. Exec into the toolbox pod and run the backup-utility command:
   1. find your Gitlab Toolbox pod 
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
You can read more on the upstream documentation: https://docs.gitlab.com/charts/backup-restore/restore.html#restoring-the-backup-file
