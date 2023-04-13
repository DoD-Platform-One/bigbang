## Handling Scheduling in the Chart
To handle scheduling in the chart for a Renovate configuration, you can use a Kubernetes CronJob object, which allows you to schedule jobs to run at specific intervals. To configure the scheduling, you will need to modify the schedule field in the cronjob section of the values.yaml file.

The schedule option allows you to define times of week or month for Renovate updates. Running Renovate around the clock can be too "noisy" for some projects. To reduce the noise you can use the schedule config option to limit the time frame in which Renovate will perform actions on your repository. You can use the standard Cron syntax and Later syntax to define your schedule.

The default value for schedule is `0 1 * * *` for at `01:00 everyday`.

The easiest way to define a schedule is to use a preset if one of them fits your requirements. See Schedule presets for details and feel free to request a new one in the source repository if you think others would benefit from it too.

##### Later examples
Otherwise, here are some text schedules that are known to work:
```
every weekend
before 5:00am
after 10pm and before 5:00am
after 10pm and before 5am every weekday
on friday and saturday
every 3 months on the first day of the month
* 0 2 * *
```
##### Cron Syntax
```R
*    *    *    *    *
-    -    -    -    -
|    |    |    |    |
|    |    |    |    +----- day of the week (0 - 6) (Sunday=0)
|    |    |    +---------- month (1 - 12)
|    |    +--------------- day of the month (1 - 31)
|    +-------------------- hour (0 - 23)
+------------------------- minute (0 - 59)
```

> For example, to run the Renovate job every day at 1:00 AM, you would set the schedule field to `0 1 * * *`

### Other Options

You can also configure other options in the CronJob section, such as suspend to temporarily disable the job, concurrencyPolicy to control how multiple instances of the job are run, and startingDeadlineSeconds to specify the maximum amount of time to wait for a job to start before considering it failed.

* `suspend` - If set to `true`, the job will be suspended and will not be executed.
* `concurrencyPolicy` - This determines how the job handles concurrent executions. Valid values are `Allow`, `Forbid`, and `Replace`.
* `failedJobsHistoryLimit` - This defines the number of failed jobs that will be kept in history.
* `successfulJobsHistoryLimit` - This defines the number of successful jobs that will be kept in history.
* `jobRestartPolicy` - This determines how the job will be restarted when it fails. Valid values are `Never` and `OnFailure`.
* `jobBackoffLimit` - This defines the maximum number of retries that can be attempted before the job is considered failed.
* `startingDeadlineSeconds` - This defines the deadline for starting the job. If the job is not started before the deadline, it will be cancelled.

#
Once you have configured the schedule in the values.yaml file, you can deploy the Renovate chart using `helm install` or `helm upgrade` commands. The Renovate job will then run according to the specified schedule.

### Example Yaml
```yaml
packages:
  renovate:
    enabled: true
    git:
      repo: https://repo1.dso.mil/big-bang/product/packages/renovate.git
      tag: 32.38.0-bb.1
    values:
      cronjob:
        # At 01:00 every day
        schedule: '0 1 * * *'
        # -- If it is set to true, all subsequent executions are suspended. This setting does not apply to already started executions.
        suspend: false
        annotations: {}
        labels: {}
        concurrencyPolicy: ''
        failedJobsHistoryLimit: ''
        successfulJobsHistoryLimit: ''
        jobRestartPolicy: Never
        jobBackoffLimit: ''
        startingDeadlineSeconds: ''

  ``` 