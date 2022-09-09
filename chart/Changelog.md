# Change Log

## 1.5.1

**Release date:** 2022-08-24

![AppVersion: 7.19.0](https://img.shields.io/static/v1?label=AppVersion&message=7.19.0&color=success&logo=)
![Kubernetes: >=1.19.x-0](https://img.shields.io/static/v1?label=Kubernetes&message=>=1.19.x-0&color=informational&logo=kubernetes)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)

* Fix [SCALE-76](https://jira.atlassian.com/browse/SCALE-76): Fixed Confluence when Synchrony is enabled (#443)
* Update the default Confluence version to 7.19.0 (#445)


## 1.5.0

**Release date:** 2022-07-14

![AppVersion: 7.13.8](https://img.shields.io/static/v1?label=AppVersion&message=7.13.8&color=success&logo=)
![Kubernetes: >=1.19.x-0](https://img.shields.io/static/v1?label=Kubernetes&message=>=1.19.x-0&color=informational&logo=kubernetes)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)

* Fix [SCALE-68](https://jira.atlassian.com/browse/SCALE-68): Use the custom ports for Confluence service (#419)
* Fix [SCALE-69](https://jira.atlassian.com/browse/SCALE-69): Use the custom ports for Synchrony service (#419)
* Fix [ISSUE-225](https://github.com/atlassian/data-center-helm-charts/issues/225): Fixed Synchrony ingress path (#429)
* Update the default Confluence version to 7.13.8 (#430)

## 1.4.1

**Release date:** 2022-06-09

![AppVersion: 7.13.7](https://img.shields.io/static/v1?label=AppVersion&message=7.13.7&color=success&logo=)
![Kubernetes: >=1.19.x-0](https://img.shields.io/static/v1?label=Kubernetes&message=>=1.19.x-0&color=informational&logo=kubernetes)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)

* Update the default Confluence version to 7.13.7 (#417) - Mitigate [CVE-2022-26134](https://confluence.atlassian.com/doc/confluence-security-advisory-2022-06-02-1130377146.html)


## 1.4.0

**Release date:** 2022-05-25

![AppVersion: 7.13.6](https://img.shields.io/static/v1?label=AppVersion&message=7.13.6&color=success&logo=)
![Kubernetes: >=1.19.x-0](https://img.shields.io/static/v1?label=Kubernetes&message=>=1.19.x-0&color=informational&logo=kubernetes)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)

* Make pod securityContext optional (#389)
* Fixed additionalHosts (#392)
* Support for configuring ingress proxy settings via values.yaml (#402)
* Add ATL_PROXY_NAME and ATL_PROXY_PORT to Confluence (#407)
* Update Confluence version to 7.13.6 (#412)


## 1.3.0

**Release date:** 2022-03-24

![AppVersion: 7.13.5](https://img.shields.io/static/v1?label=AppVersion&message=7.13.5&color=success&logo=)
![Kubernetes: >=1.19.x-0](https://img.shields.io/static/v1?label=Kubernetes&message=>=1.19.x-0&color=informational&logo=kubernetes)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)


* DCD-1471: Add support for separate Synchrony volumes (#390)
* Update Confluence version to 7.13.5 (#396)

## 1.2.0

**Release date:** 2022-02-14

![AppVersion: 7.13.4-jdk11](https://img.shields.io/static/v1?label=AppVersion&message=7.13.2-jdk11&color=success&logo=)
![Kubernetes: >=1.19.x-0](https://img.shields.io/static/v1?label=Kubernetes&message=>=1.19.x-0&color=informational&logo=kubernetes)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)


* DCD-1452: Updated appVersion to the latest product LTS version. (#378)
* Improvements on [documentation](https://github.com/atlassian/data-center-helm-charts/) (#370, #357)
* Updated Atlassian charts to use common definitions (#303)
* Added service account annotation (#363)
* Added new feature additionalVolumeClaimTemplates and provided example in documentation (#334, #368)
* Added new feature podLabels (#364)
* Added new feature to define loadBalancerIP (#365)
* Define podAnnotations as template to allow overrides (#341)
* DCKUBE-738: Added topologySpreadConstraints to products (#351)
* Set ActiveProcessorCount automatically based on Values.<product>.resources.container.requests.cpu (#352)
* Added new feature additionalPorts (for jmx-monitoring) (#353)


## 1.1.0 

**Release date:** 2021-11-03

![AppVersion: 7.13.2-jdk11](https://img.shields.io/static/v1?label=AppVersion&message=7.13.2-jdk11&color=success&logo=)
![Kubernetes: >=1.19.x-0](https://img.shields.io/static/v1?label=Kubernetes&message=>=1.19.x-0&color=informational&logo=kubernetes)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)


* DCKUBE-721: Update version in Chart.yaml files 
* DCKUBE-733: Update the product versions (#345) 
* DCKUBE-739: Fix typos (#337) 
* DCKUBE-739: Make securityContext changes backward compatible (#332) 
* Roll Statefulset Pods if ConfigMap changes (#315) 
* DCKUBE-677: Make security context more flexible (#321) 
* DCKUBE-722: Enable configuring ingress.class name (#313) 
* DCKUBE-678: Add schedulerName to StatefulSet (#301) 
* DCKUBE-686: Decrease Confluence failover time (#299) 


## 1.0.0

This is the first officially supported version of the Helm chart.

![AppVersion: 7.13.0-jdk11](https://img.shields.io/static/v1?label=AppVersion&message=7.13.0-jdk11&color=success&logo=)
![Kubernetes: >=1.19.x-0](https://img.shields.io/static/v1?label=Kubernetes&message=>=1.19.x-0&color=informational&logo=kubernetes)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)


* DCKUBE-670: Fix Synchrony ingress path (#281)
* DCKUBE-621: Improvements to graceful shutdown (#282)
* DCKUBE-654: Make synchrony configurable (#283)
* Improved [documentation](https://github.com/atlassian/data-center-helm-charts/) (#275, #276, #277, #279, #280, #284, #285, #289, #290, #291, #293. #295)


## 0.16.0

![AppVersion: 7.13.0-jdk11](https://img.shields.io/static/v1?label=AppVersion&message=7.13.0-jdk11&color=success&logo=)
![Kubernetes: >=1.19.x-0](https://img.shields.io/static/v1?label=Kubernetes&message=>=1.19.x-0&color=informational&logo=kubernetes)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)


* DCKUBE-598: Enable NFS permission fixer by default (#241)
* DCKUBE-581: Enable configuration for SET_PERMISSIONS docker image variable (#261)
* DCKUBE-613: Configurable grace periods (#249)
* DCKUBE-614: Upgrade Confluence to 7.13.0 LTS version (#257)
* DCKUBE-612: Improve Confluence shutdown procedure (#250)
* DCKUBE-620: Set ContextPath as default for singress path (#263)
* DCKUBE-635: Fix spacing of the jvm args for debug flag (#266)
* Update the Confluence image name, as the '-server' suffix is deprecated (#259)
* Improve [documentation](https://github.com/atlassian/data-center-helm-charts/)  (#236, #243, #245, #252, #253, #256, #258, #260, #263, #268, #270, #272)


## 0.15.0

![AppVersion: 7.12.4-jdk11](https://img.shields.io/static/v1?label=AppVersion&message=7.12.4-jdk11&color=success&logo=)
![Kubernetes: >=1.19.x-0](https://img.shields.io/static/v1?label=Kubernetes&message=>=1.19.x-0&color=informational&logo=kubernetes)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)


* Add Service annotations (#209)
* DCKUBE-435: Renamed the 'master' branch to 'main' and set it as default (#232)
* DCKUBE-453: Add support for providing a custom fluentd start command (#218)
* DCKUBE-596: Update Confluence version to 7.12.4-jdk11 (#238)
* Update EKS cluster yaml example (#227)
* Improve [documentation](https://github.com/atlassian/data-center-helm-charts/) (#206, #222, #223, #228, #229, #231, #233, #235)


## 0.14.0

![AppVersion: 7.12.3-jdk11](https://img.shields.io/static/v1?label=AppVersion&message=7.12.3-jdk11&color=success&logo=)
![Kubernetes: >=1.19.x-0](https://img.shields.io/static/v1?label=Kubernetes&message=>=1.19.x-0&color=informational&logo=kubernetes)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)

* DCKUBE-529: Update Confluence version to 7.12.3-jdk11 (#212)


## 0.13.0

![AppVersion: 7.12.2-jdk11](https://img.shields.io/static/v1?label=AppVersion&message=7.12.2-jdk11&color=success&logo=)
![Kubernetes: >=1.19.x-0](https://img.shields.io/static/v1?label=Kubernetes&message=>=1.19.x-0&color=informational&logo=kubernetes)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)


* DCKUBE-527: Fix Synchrony resource requests and limits (#210)
* DCKUBE-54: Volume docs updates (#188)


## 0.12.0

![AppVersion: 7.12.2-jdk11](https://img.shields.io/static/v1?label=AppVersion&message=7.12.2-jdk11&color=success&logo=)
![Kubernetes: >=1.19.x-0](https://img.shields.io/static/v1?label=Kubernetes&message=>=1.19.x-0&color=informational&logo=kubernetes)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)


* DCKUBE-437: Wording improvement for warning in NOTES when PV is not used (#199) 
* DCKUBE-438: Increase the timeout for /bootstrap endpoints in the same way as for /setup to avoid the ingress timeout (#194) 
* DCKUBE-392: Improve readability of Confluence values.yaml file (#183) 
* Defining the following values in the helpers template for each chart, to allow template overrides: (#173)

### Default value changes

There has been major improvement in the documentation for the keys in `values.yaml` file but there isn't any functional
change.

## 0.11.0 

**Release date:** 2021-06-09

![AppVersion: 7.12.2-jdk11](https://img.shields.io/static/v1?label=AppVersion&message=7.12.2-jdk11&color=success&logo=)
![Kubernetes: >=1.19.x-0](https://img.shields.io/static/v1?label=Kubernetes&message=>=1.19.x-0&color=informational&logo=kubernetes)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)


* DCKUBE-348: Warning of absent persistent volume (#169) 
* DCKUBE-307: Do not print logs when testing helm installation. (#168) 
* DCKUBE-308: Print service URL after installing helm chart (#157) 
* DCKUBE-331: Mount additional libraries in DB connectivity pod. (#162) 
* DCKUBE-282: Update icons to SVG (#164) 
* DCKUBE-322: Revert previous enabling of Synchrony by default for now … (#160) 
* DCKUBE-322: Add resources stanza for Synchrony and inject values into startup (#151) 

### Default value changes

```diff
diff --git a/src/main/charts/confluence/values.yaml b/src/main/charts/confluence/values.yaml
index a39d4ae..8e148f3 100644
--- a/src/main/charts/confluence/values.yaml
+++ b/src/main/charts/confluence/values.yaml
@@ -183,6 +183,18 @@ synchrony:
     periodSeconds: 1
     # -- The number of consecutive failures of the Synchrony container readiness probe before the pod fails readiness checks
     failureThreshold: 30
+  resources:
+    jvm:
+      # -- The minimum amount of heap memory that will be used by the Synchrony JVM
+      minHeap: "1g"
+      # -- The maximum amount of heap memory that will be used by the Synchrony JVM
+      maxHeap: "2g"
+      # -- The memory allocated for the Synchrony stack
+      stackSize: "2048k"
+    container: 
+      requests:
+        cpu: "2"
+        memory: "2.5G"
   # -- The base URL of the Synchrony service.
   # This will be the URL that users' browsers will be given to communicate with Synchrony, as well as the URL that the
   # Confluence service will use to communicate directly with Synchrony, so the URL must be resovable both from inside and
```

## 0.10.0 

**Release date:** 2021-06-01

![AppVersion: 7.12.0-jdk11](https://img.shields.io/static/v1?label=AppVersion&message=7.12.0-jdk11&color=success&logo=)
![Kubernetes: >=1.19.x-0](https://img.shields.io/static/v1?label=Kubernetes&message=>=1.19.x-0&color=informational&logo=kubernetes)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)


* Version 0.10.0 
* DCKUBE-332: Update the minimal supported kubernetes version v1.19 (#154) 

### Default value changes

```diff
# No changes in this release
```

## 0.9.0 

**Release date:** 2021-05-25

![AppVersion: 7.12.0-jdk11](https://img.shields.io/static/v1?label=AppVersion&message=7.12.0-jdk11&color=success&logo=)
![Kubernetes: >=1.17.x-0](https://img.shields.io/static/v1?label=Kubernetes&message=>=1.17.x-0&color=informational&logo=kubernetes)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)


* Version 0.9.0 
* Merge branch 'master' into DCKUBE-317-additional-libraries-for-synchron 
* DCKUBE-317: Fix new line remover 
* initial commit - changed the max-body-size of request to 250MB for all products and documented in CONFIG.md (#140) 
* DCKUBE-317: Fix comment for Synchrony additional library 
* DCKUBE-317: Allow additional volumes mounted to Synchrony 
* DCKUBE-292: fix the problem with empty ingress URL in Confluence 
* DCKUBE-317: Added additional libraries for synchrony 
* Update values.yaml (#139) 
* Merge branch 'master' into dckube-267-define-minimum-compute-resources 
* README update for 0.8.0 
* Merge branch 'dckube-267-define-minimum-compute-resources' of github.com:https://github.com/atlassian/data-center-helm-charts/data-center-helm-charts into dckube-267-define-minimum-compute-resources 
* DCKUBE-267: Update cpu request sizes 
* Merge branch 'master' into dckube-267-define-minimum-compute-resources 
* DCKUBE-267: Update cpu request sizes 
* Add Ingress path to Confluence setup ingress and add tests (#136) 
* Added ingress.host into values.yaml with corresponding value injection in ingress.yaml for all apps. Defaults to / (#134) 
* DCKUBE-267: Wording updates 
* DCKUBE-267: Initial commit 
* DCKUBE-205: fix a provisioning a problem when debug flag is false 
* Merge remote-tracking branch 'origin/issue-712/DCKUBE-205-make-possible-to-run-k8s-tests-in-local-cluster' into issue-712/DCKUBE-205-make-possible-to-run-k8s-tests-in-local-cluster 
* Revert "DCKUBE-205: define the ingress template as a library" 
* Revert "DCKUBE-205: use diffent ingress name for setup ingress" 
* Revert "DCKUBE-205: fix a typo for ingress definitions" 
* Merge branch 'master' into issue-712/DCKUBE-205-make-possible-to-run-k8s-tests-in-local-cluster 
* Add Crowd as a tested product (#128) 
* DCKUBE-205: address review comments 
* DCKUBE-205: fix a typo for ingress definitions 
* DCKUBE-205: use diffent ingress name for setup ingress 
* DCKUBE-205: define the ingress template as a library 
* DCKUBE-205: more docs 
* DCKUBE-205: fix the unit tests 

### Default value changes

```diff
diff --git a/src/main/charts/confluence/values.yaml b/src/main/charts/confluence/values.yaml
index da3a956..a39d4ae 100644
--- a/src/main/charts/confluence/values.yaml
+++ b/src/main/charts/confluence/values.yaml
@@ -11,7 +11,7 @@ image:
 
 serviceAccount:
   # -- Specifies the name of the ServiceAccount to be used by the pods.
-  # If not specified, but the the "serviceAccount.create" flag is set, then the ServiceAccount name will be auto-generated,
+  # If not specified, but the "serviceAccount.create" flag is set, then the ServiceAccount name will be auto-generated,
   # otherwise the 'default' ServiceAccount will be used.
   name:
   # -- true if a ServiceAccount should be created, or false if it already exists
@@ -34,10 +34,10 @@ serviceAccount:
 database:
   # -- The type of database being used.
   # Valid values include 'postgresql', 'mysql', 'oracle', 'mssql'.
-  # If not specified, then it will need to be provided via browser during initial startup.
+  # If not specified, then it will need to be provided via the browser during initial startup.
   type:
   # -- The JDBC URL of the database to be used by Confluence and Synchrony, e.g. jdbc:postgresql://host:port/database
-  # If not specified, then it will need to be provided via browser during initial startup.
+  # If not specified, then it will need to be provided via the browser during initial startup.
   url:
   credentials:
     # -- The name of the Kubernetes Secret that contains the database login credentials.
@@ -74,16 +74,16 @@ confluence:
     # -- The port on which the Confluence container listens for Hazelcast traffic
     hazelcast: 5701
   license:
-    # -- The name of the Kubernetes Secret which contains the Confluence license key.
+    # -- The name of the Kubernetes Secret that contains the Confluence license key.
     # If specified, then the license will be automatically populated during Confluence setup.
     # Otherwise, it will need to be provided via the browser after initial startup.
     secretName:
-    # -- The key in the Kubernetes Secret which contains the Confluence license key
+    # -- The key in the Kubernetes Secret that contains the Confluence license key
     secretKey: license-key
   readinessProbe:
     # -- The initial delay (in seconds) for the Confluence container readiness probe, after which the probe will start running
     initialDelaySeconds: 10
-    # -- How often (in seconds) the Confluence container readiness robe will run
+    # -- How often (in seconds) the Confluence container readiness probe will run
     periodSeconds: 5
     # -- The number of consecutive failures of the Confluence container readiness probe before the pod fails readiness checks
     failureThreshold: 30
@@ -105,31 +105,35 @@ confluence:
 
   resources:
     jvm:
+      # -- JVM memory arguments below are based on the defaults defined for the Confluence docker container, see:
+      # https://bitbucket.org/atlassian-docker/docker-atlassian-confluence-server/src/master/#markdown-header-memory-heap-size
+      #
       # -- The maximum amount of heap memory that will be used by the Confluence JVM
       maxHeap: "1g"
       # -- The minimum amount of heap memory that will be used by the Confluence JVM
       minHeap: "1g"
       # -- The memory reserved for the Confluence JVM code cache
-      reservedCodeCache: "512m"
+      reservedCodeCache: "256m"
     # -- Specifies the standard Kubernetes resource requests and/or limits for the Confluence container.
     # It is important that if the memory resources are specified here, they must allow for the size of the Confluence JVM.
     # That means the maximum heap size, the reserved code cache size, plus other JVM overheads, must be accommodated.
     # Allowing for (maxHeap+codeCache)*1.5 would be an example.
-    container: {}
+    container: 
     #  limits:
-    #    cpu: "4"
-    #    memory: "2G"
-    #  requests:
-    #    cpu: "4"
+    #    cpu: "1"
     #    memory: "2G"
+      requests:
+        cpu: "2" # -- If changing the cpu value update additional JVM arg 'ActiveProcessorCount' below
+        memory: "2G"
 
   # -- Specifies a list of additional arguments that can be passed to the Confluence JVM, e.g. system properties
-  additionalJvmArgs: []
-#    - -Dfoo=bar
-#    - -Dfruit=lemon
+  additionalJvmArgs:
+    # -- The value defined for ActiveProcessorCount should correspond to that provided for 'container.requests.cpu'
+    # see: https://docs.oracle.com/en/java/javase/11/tools/java.html#GUID-3B1CE181-CD30-4178-9602-230B800D4FAE
+    - -XX:ActiveProcessorCount=2
 
   # -- Specifies a list of additional Java libraries that should be added to the Confluence container.
-  # Each item in the list should specify the name of the volume which contain the library, as well as the name of the
+  # Each item in the list should specify the name of the volume that contains the library, as well as the name of the
   # library file within that volume's root directory. Optionally, a subDirectory field can be included to specify which
   # directory in the volume contains the library file.
   additionalLibraries: []
@@ -153,10 +157,14 @@ confluence:
   # See https://hub.docker.com/r/atlassian/confluence-server for supported variables.
   additionalEnvironmentVariables: []
 
+  jvmDebug:
+    # -- If set to true, Confluence JVM will be started with debugging port 5005 open.
+    enabled: false
+
 synchrony:
-  # -- True if Synchrony (i.e. Collaborative Editing) should be enabled.
+  # -- True if Synchrony (i.e. collaborative editing) should be enabled.
   # This will result in a separate StatefulSet and Service to be created for Synchrony.
-  # If disabled, then Collaborative Editing will be disabled in Confluence.
+  # If disabled, then collaborative editing will be disabled in Confluence.
   enabled: false
   service:
     # -- The port on which the Synchrony Kubernetes service will listen
@@ -171,7 +179,7 @@ synchrony:
   readinessProbe:
     # -- The initial delay (in seconds) for the Synchrony container readiness probe, after which the probe will start running
     initialDelaySeconds: 5
-    # -- How often (in seconds) the Synchrony container readiness robe will run
+    # -- How often (in seconds) the Synchrony container readiness probe will run
     periodSeconds: 1
     # -- The number of consecutive failures of the Synchrony container readiness probe before the pod fails readiness checks
     failureThreshold: 30
@@ -180,6 +188,14 @@ synchrony:
   # Confluence service will use to communicate directly with Synchrony, so the URL must be resovable both from inside and
   # outside the Kubernetes cluster.
   ingressUrl:
+  # -- Specifies a list of additional Java libraries that should be added to the Synchrony container.
+  # Each item in the list should specify the name of the volume which contain the library, as well as the name of the
+  # library file within that volume's root directory. Optionally, a subDirectory field can be included to specify which
+  # directory in the volume contains the library file.
+  additionalLibraries: []
+#    - volumeName:
+#      subDirectory:
+#      fileName:
 
 ingress:
   # -- True if an Ingress Resource should be created.
@@ -193,9 +209,11 @@ ingress:
   # -- The max body size to allow. Requests exceeding this size will result
   # in an 413 error being returned to the client.
   # https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#custom-max-body-size
-  maxBodySize: 10m
+  maxBodySize: 250m
   # -- The fully-qualified hostname of the Ingress Resource.
   host:
+  # -- The base path for the ingress rule.
+  path: "/"
   # -- The custom annotations that should be applied to the Ingress 
   # Resource when not using the Kubernetes ingress-nginx controller.
   annotations: {}
@@ -206,9 +224,9 @@ ingress:
   tlsSecretName:
 
 fluentd:
-  # -- True if the fluentd sidecar should be added to each pod
+  # -- True if the Fluentd sidecar should be added to each pod
   enabled: false
-  # -- True if a custom config should be used for fluentd
+  # -- True if a custom config should be used for Fluentd
   customConfigFile: false
   # -- Custom fluent.conf file
   # fluent.conf: |
@@ -225,18 +243,18 @@ fluentd:
   #     tag confluence-access-logs
   #   </source>
 
- # -- The name of the image containing the fluentd sidecar
+ # -- The name of the image containing the Fluentd sidecar
   imageName: fluent/fluentd-kubernetes-daemonset:v1.11.5-debian-elasticsearch7-1.2
-  # -- The port on which the fluentd sidecar will listen
+  # -- The port on which the Fluentd sidecar will listen
   httpPort: 9880
   elasticsearch:
-    # -- True if fluentd should send all log events to an elasticsearch service.
+    # -- True if Fluentd should send all log events to an Elasticsearch service.
     enabled: true
-    # -- The hostname of the Elasticsearch service that fluentd should send logs to.
+    # -- The hostname of the Elasticsearch service that Fluentd should send logs to.
     hostname: elasticsearch
-    # -- The prefix of the elasticsearch index name that will be used
+    # -- The prefix of the Elasticsearch index name that will be used
     indexNamePrefix: confluence
-  # -- Specify custom volumes to be added to fluentd container (e.g. more log sources)
+  # -- Specify custom volumes to be added to Fluentd container (e.g. more log sources)
   extraVolumes: []
   # - name: local-home
   #   mountPath: /opt/atlassian/confluence/logs
@@ -258,9 +276,9 @@ volumes:
         requests:
           storage: 1Gi
     # -- When persistentVolumeClaim.create is false, then this value can be used to define a standard Kubernetes
-    # volume which will be used for the local-home volumes. If not defined, then defaults to an emptyDir volume.
+    # volume that will be used for the local-home volumes. If not defined, then defaults to an emptyDir volume.
     customVolume: {}
-    # -- The path within the Confluence container which the local-home volume should be mounted.
+    # -- The path within the Confluence container where the local-home volume should be mounted.
     mountPath: "/var/atlassian/application-data/confluence"
   sharedHome:
     persistentVolumeClaim:
@@ -273,11 +291,11 @@ volumes:
         requests:
           storage: 1Gi
     # -- When persistentVolumeClaim.create is false, then this value can be used to define a standard Kubernetes
-    # volume which will be used for the shared-home volume. If not defined, then defaults to an emptyDir (i.e. unshared) volume.
+    # volume, which will be used for the shared-home volume. If not defined, then defaults to an emptyDir (i.e. unshared) volume.
     customVolume: {}
     # -- Specifies the path in the Confluence container to which the shared-home volume will be mounted.
     mountPath: "/var/atlassian/application-data/shared-home"
-    # -- Specifies the sub-directory of the shared-home volume which will be mounted in to the Confluence container.
+    # -- Specifies the sub-directory of the shared-home volume that will be mounted in to the Confluence container.
     subPath:
     nfsPermissionFixer:
       # -- If enabled, this will alter the shared-home volume's root directory so that Confluence can write to it.
@@ -315,8 +333,8 @@ additionalLabels: {}
 # -- Additional existing ConfigMaps and Secrets not managed by Helm that should be mounted into server container
 # configMap and secret are two available types (camelCase is important!)
 # mountPath is a destination directory in a container and key is file name
-# name references existing ConfigMap or secret name. VolumeMount and Volumes are added with this name + index position,
-# for example custom-config-0, keystore-2
+# name references existing ConfigMap or secret name. VolumeMount and Volumes are added with this name and index position,
+# for example, custom-config-0, keystore-2
 additionalFiles: []
 
 #  - name: custom-config
```

## 0.7.0 

**Release date:** 2021-05-10

![AppVersion: 7.12.0-jdk11](https://img.shields.io/static/v1?label=AppVersion&message=7.12.0-jdk11&color=success&logo=)
![Kubernetes: >=1.17.x-0](https://img.shields.io/static/v1?label=Kubernetes&message=>=1.17.x-0&color=informational&logo=kubernetes)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)


* Merge branch 'master' into issue-712/DCKUBE-205-make-possible-to-run-k8s-tests-in-local-cluster 

### Default value changes

```diff
diff --git a/src/main/charts/confluence/values.yaml b/src/main/charts/confluence/values.yaml
index 08095d6..da3a956 100644
--- a/src/main/charts/confluence/values.yaml
+++ b/src/main/charts/confluence/values.yaml
@@ -208,7 +208,24 @@ ingress:
 fluentd:
   # -- True if the fluentd sidecar should be added to each pod
   enabled: false
-  # -- The name of the image containing the fluentd sidecar
+  # -- True if a custom config should be used for fluentd
+  customConfigFile: false
+  # -- Custom fluent.conf file
+  # fluent.conf: |
+  fluentdCustomConfig: {}
+  # fluent.conf: |
+  #   <source>
+  #     @type tail
+  #     <parse>
+  #     @type multiline
+  #     format_firstline /\d{4}-\d{1,2}-\d{1,2}/
+  #     </parse>
+  #     path /opt/atlassian/confluence/logs/access_log.*
+  #     pos_file /tmp/confluencelog.pos
+  #     tag confluence-access-logs
+  #   </source>
+
+ # -- The name of the image containing the fluentd sidecar
   imageName: fluent/fluentd-kubernetes-daemonset:v1.11.5-debian-elasticsearch7-1.2
   # -- The port on which the fluentd sidecar will listen
   httpPort: 9880
@@ -219,7 +236,12 @@ fluentd:
     hostname: elasticsearch
     # -- The prefix of the elasticsearch index name that will be used
     indexNamePrefix: confluence
-
+  # -- Specify custom volumes to be added to fluentd container (e.g. more log sources)
+  extraVolumes: []
+  # - name: local-home
+  #   mountPath: /opt/atlassian/confluence/logs
+  #   subPath: log
+  #   readOnly: true
 # -- Specify additional annotations to be added to all Confluence and Synchrony pods
 podAnnotations: {}
 #  "name": "value"
@@ -296,6 +318,7 @@ additionalLabels: {}
 # name references existing ConfigMap or secret name. VolumeMount and Volumes are added with this name + index position,
 # for example custom-config-0, keystore-2
 additionalFiles: []
+
 #  - name: custom-config
 #    type: configMap
 #    key: log4j.properties
```

## 0.1.0 

**Release date:** 2021-05-07

![AppVersion: 7.9.0-jdk11](https://img.shields.io/static/v1?label=AppVersion&message=7.9.0-jdk11&color=success&logo=)
![Kubernetes: >=1.17.x-0](https://img.shields.io/static/v1?label=Kubernetes&message=>=1.17.x-0&color=informational&logo=kubernetes)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)


* DCKUBE-205 Allow addition of entries in /etc/hosts for each pod. 

### Default value changes

```diff
diff --git a/src/main/charts/confluence/values.yaml b/src/main/charts/confluence/values.yaml
index 0ae8cf2..08095d6 100644
--- a/src/main/charts/confluence/values.yaml
+++ b/src/main/charts/confluence/values.yaml
@@ -308,3 +308,12 @@ additionalFiles: []
 #    type: secret
 #    key: keystore.jks
 #    mountPath: /var/ssl
+
+# -- Additional host aliases for each pod, equivalent to adding them to the /etc/hosts file. See
+# https://kubernetes.io/docs/concepts/services-networking/add-entries-to-pod-etc-hosts-with-host-aliases/ for more
+# information.
+additionalHosts: []
+#  - ip: "127.0.0.1"
+#    hostnames:
+#    - "foo.local"
+#    - "bar.local"
```

## 0.7.0 

**Release date:** 2021-05-07

![AppVersion: 7.12.0-jdk11](https://img.shields.io/static/v1?label=AppVersion&message=7.12.0-jdk11&color=success&logo=)
![Kubernetes: >=1.17.x-0](https://img.shields.io/static/v1?label=Kubernetes&message=>=1.17.x-0&color=informational&logo=kubernetes)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)


* Release 0.7.0 (#123) 
* Update charts descriptors (#121) 
* feat (fluentd) extra fluentd customization to (jira / confluence) helm charts (#95) 
* Update application versions (#116) 
* DCKUBE-103: add a system to enable collab editing by default 
* indenting jira's additionalFiles volume mounts and adding to confluence 
* Merge branch 'master' into issue-712/DCKUBE-205-make-possible-to-run-k8s-tests-in-local-cluster 
* DCKUBE-205: use separate ingress for setup 
* Update documentation for 0.6.0 release 
* DCKUBE-205: increase the default Nginx timeout 
* feat(perms): Paramterize setPermissions boolean flag (#97) 
* DCKUBE-205: provide the ability to open debug port on Connie JVM 
* DCKUBE-205: provide the ability to open debug port on Connie JVM 
* DCKUBE-205: provide the ability to open debug port on Connie JVM 
* DCKUBE-231: Max body size should be configurable 
* DCKUBE-90: Additional details relating to the Ingress controller 
* Introducing an easier way to mount secrets and configmaps (#102) 
* Merge branch 'master' into dckube-131-nfs-fixer-removal 
* DCKUBE-131: fix for initContainer being synthesized twice 
* Merge branch 'master' into dckube-131-nfs-fixer-removal 
* DCKUBE-131: Updates to template formatting and readme wording 
* Merge pull request #98 from https://github.com/atlassian/data-center-helm-charts/dckube-131-nfs-fixer-removal 
* DCKUBE-131: Alter NFS permissions via init container 
* feat(range): Fix support for multiple plugins 
* ISSUE-85: Add context path for Confluence 
* Update READMEs for 0.5.0 release 
* DCNG-1021 fix stray CR for Confluence 
* DCNG-976 remove unnecessary local-home volume mount from confluence fluentd container 
* DCNG-976 replace Confluence chart fluentd log file tail input, with HTTP events posted direct from Confluence 
* Merge pull request #59 from https://github.com/atlassian/data-center-helm-charts/minor-cleanup-and-Azure-related-fixes 
* DCNG-976 remove duplicate additionalContainers from confluence chart 
* Merge remote-tracking branch 'origin/master' into DCNG-976-efk 
* Fix gid value 
* Merge remote-tracking branch 'origin/master' into DCNG-976-efk 
* OpenShift support (#56) 
* Merge remote-tracking branch 'origin/master' into DCNG-976-efk 
* DCNG-977 enable access logs in Confluence by default, for consistency with Jira+BB 
* DCNG-977 document use of double-mounted local-home volume 
* DCNG-783 minor cleanup and Azure related fixes 
* DCNG-977 capture Confluence tomcat/access logs into local-home volume 
* DCNG-976 limit fluentd to just atlassian-confluence.log 
* DCNG-976 use fluent/fluentd-kubernetes-daemonset for the sidecar 
* DCNG-976 use subPath to limit the scope of the local-hme volumeMount in the fluentd container. 
* DCNG-976 add support for EFK (Elasticsearch/Fluentd/Kibana) stack 
* DCNG-925 support for BYO NFS server 
* DCNG-961 Set confluence.clusterNodeName.useHostname sysprop 
* default customVolume chart value to empty map , to avoid helm warning 
* Add optional TLS to ingress spec 
* DCNG-892 simplify config of https/http 
* DCNG-892 update docs 
* DCNG-892 Configure the created ingress as nginx by default 
* DCNG-892 Move ingress value structure up to top level 
* DCNG-892 Add Ingress template to the Helm charts, and activate it for EKS testing 
* DCNG-927 Tweak doco for clarity 
* DCNG-927 Allow Tomcat ingress https/secure config to be changed for Jira/Confluence, and make consistent with Bitbucket 
* DCNG-921 add doco for enabling clustering 
* DCNG-921 disable clustering by defaault 
* DCNG-920 Disable Synchrony by default, but keep enabled for integration testing 
* DCNG-913 Make bitbucket/confluence license secret optional 
* DCNG-914 make jira/confluence DB config values fully optional 
* DCNG-893 move emptyDir volume defaults back into the templates 
* DCNG-893 Make localHome/sharedHome configuration more consistent by adding an optional shared-home PVC to the chart 
* rename localHome.persistentVolumeClaim.enabled to .create 
* DCNG-893 update documentation 
* DCNG-893 rework how volumes are customised in the Confluence chart 
* DCNG-893 disable PVs by default on Bitbucket and Confluence 
* DCNG-898 add a series of unit tests for the serviceAccount and image config rendering 
* DCNG-899 Added service account to db-connectivity-test 
* DCNG-897 Use "before-hook-creation,hook-succeeded" deletion policy 
* Merge remote-tracking branch 'origin/master' into DCNG-897 
* DCNG-897 Add hook-delete-policy to chart tests and nfs-fixer job 
* DCNG-894 Add a ServiceAccount, ClusterRole and ClusterRoleBinding to the Confluence chart 
* DCNG-880 Added support for custom builds in kubeVersion 
* DCNG-853 Fixed kubeVersion 
* DCNG-853 Updated products' charts 
* confluence 7.9.0 is out 
* DCNG-856 add -n to each command in NOTES.txt 
* DCNG-856 Add NOTES.txt 
* DCNG-849 avoid incorrect rendering for empty  additionalEnvironmentVariables 
* DCNG-849 check for the presense of additionalLabels so we don't render an empty {} 
* Merge pull request #6 from https://github.com/atlassian/data-center-helm-charts/DCNG-849 
* DCNG-850 add extension point for additional environment variables 
* DCNG-848 add extension point for additional labels 
* Merge pull request #3 from https://github.com/atlassian/data-center-helm-charts/DCNG-848 
* DCNG-866 Replace hardcoded image pull policy with value placeholder 
* DCNG-848 Add support for additional volumes and volume mounts 

### Default value changes

```diff
diff --git a/src/main/charts/confluence/values.yaml b/src/main/charts/confluence/values.yaml
index 88b9260..820308f 100644
--- a/src/main/charts/confluence/values.yaml
+++ b/src/main/charts/confluence/values.yaml
@@ -9,18 +9,41 @@ image:
   # -- The docker image tag to be used. Defaults to the Chart appVersion.
   tag:
 
-# -- Specifies which serviceAccount to use for the pods. If not specified, the kubernetes default will be used.
-serviceAccountName:
+serviceAccount:
+  # -- Specifies the name of the ServiceAccount to be used by the pods.
+  # If not specified, but the the "serviceAccount.create" flag is set, then the ServiceAccount name will be auto-generated,
+  # otherwise the 'default' ServiceAccount will be used.
+  name:
+  # -- true if a ServiceAccount should be created, or false if it already exists
+  create: true
+  # -- The list of image pull secrets that should be added to the created ServiceAccount
+  imagePullSecrets: []
+  clusterRole:
+    # -- Specifies the name of the ClusterRole that will be created if the "serviceAccount.clusterRole.create" flag is set.
+    # If not specified, a name will be auto-generated.
+    name:
+    # -- true if a ClusterRole should be created, or false if it already exists
+    create: true
+  clusterRoleBinding:
+    # -- Specifies the name of the ClusterRoleBinding that will be created if the "serviceAccount.clusterRoleBinding.create" flag is set
+    # If not specified, a name will be auto-generated.
+    name:
+    # -- true if a ClusterRoleBinding should be created, or false if it already exists
+    create: true
 
 database:
   # -- The type of database being used.
   # Valid values include 'postgresql', 'mysql', 'oracle', 'mssql'.
+  # If not specified, then it will need to be provided via browser during initial startup.
   type:
   # -- The JDBC URL of the database to be used by Confluence and Synchrony, e.g. jdbc:postgresql://host:port/database
+  # If not specified, then it will need to be provided via browser during initial startup.
   url:
   credentials:
     # -- The name of the Kubernetes Secret that contains the database login credentials.
-    secretName: confluence-database-credentials
+    # If specified, then the credentials will be automatically populated during Confluence setup.
+    # Otherwise, they will need to be provided via the browser after initial startup.
+    secretName:
     # -- The key in the Secret used to store the database login username
     usernameSecretKey: username
     # -- The key in the Secret used to store the database login password
@@ -32,16 +55,29 @@ confluence:
     port: 80
     # -- The type of Kubernetes service to use for Confluence
     type: ClusterIP
-  # -- The GID used by the Confluence docker image
-  gid: "2002"
+    # -- The Tomcat context path that Confluence will use. The ATL_TOMCAT_CONTEXTPATH will be set automatically
+    contextPath:
+  # -- Enable or disable security context in StatefulSet template spec. Enabled by default with UID 2002.
+  # -- Disable when deploying to OpenShift, unless anyuid policy is attached to a service account
+  securityContext:
+    enabled: true
+    # -- The GID used by the Confluence docker image
+    gid: "2002"
+  # -- The umask used by the Confluence process when it creates new files.
+  # Default is 0022, which makes the new files read/writeable by the Confluence user, and readable by everyone else.
+  umask: "0022"
+  # -- Boolean to define whether to set home directory permissions on startup of Confluence container. Set to false to disable this behaviour.
+  setPermissions: false
   ports:
     # -- The port on which the Confluence container listens for HTTP traffic
     http: 8090
     # -- The port on which the Confluence container listens for Hazelcast traffic
     hazelcast: 5701
   license:
-    # -- The name of the Kubernetes Secret which contains the Confluence license key
-    secretName: confluence-license
+    # -- The name of the Kubernetes Secret which contains the Confluence license key.
+    # If specified, then the license will be automatically populated during Confluence setup.
+    # Otherwise, it will need to be provided via the browser after initial startup.
+    secretName:
     # -- The key in the Kubernetes Secret which contains the Confluence license key
     secretKey: license-key
   readinessProbe:
@@ -51,6 +87,22 @@ confluence:
     periodSeconds: 5
     # -- The number of consecutive failures of the Confluence container readiness probe before the pod fails readiness checks
     failureThreshold: 30
+
+  accessLog:
+    # -- True if access logging should be enabled.
+    enabled: true
+    # -- The path within the Confluence container where the local-home volume should be mounted in order to capture access logs.
+    mountPath: "/opt/atlassian/confluence/logs"
+    # -- The subdirectory within the local-home volume where access logs should be stored.
+    localHomeSubPath: "logs"
+
+  clustering:
+    # -- Set to true if Data Center clustering should be enabled
+    # This will automatically configure cluster peer discovery between cluster nodes.
+    enabled: false
+    # -- Set to true if the Kubernetes pod name should be used as the end-user-visible name of the Data Center cluster node.
+    usePodNameAsClusterNodeName: true
+
   resources:
     jvm:
       # -- The maximum amount of heap memory that will be used by the Confluence JVM
@@ -93,7 +145,19 @@ confluence:
 #      subDirectory:
 #      fileName:
 
+  # -- Defines any additional volumes mounts for the Confluence container.
+  # These can refer to existing volumes, or new volumes can be defined in volumes.additional.
+  additionalVolumeMounts: []
+
+  # -- Defines any additional environment variables to be passed to the Confluence container.
+  # See https://hub.docker.com/r/atlassian/confluence-server for supported variables.
+  additionalEnvironmentVariables: []
+
 synchrony:
+  # -- True if Synchrony (i.e. Collaborative Editing) should be enabled.
+  # This will result in a separate StatefulSet and Service to be created for Synchrony.
+  # If disabled, then Collaborative Editing will be disabled in Confluence.
+  enabled: false
   service:
     # -- The port on which the Synchrony Kubernetes service will listen
     port: 80
@@ -117,37 +181,118 @@ synchrony:
   # outside the Kubernetes cluster.
   ingressUrl:
 
+ingress:
+  # -- True if an Ingress Resource should be created.
+  create: false
+  # -- True if the created Ingress Resource is to use the Kubernetes ingress-nginx controller:
+  # https://kubernetes.github.io/ingress-nginx/
+  # This will populate the Ingress Resource with annotations for the Kubernetes ingress-nginx controller.
+  # Set to false if a different controller is to be used, in which case the appropriate annotations for that
+  # controller need to be specified.
+  nginx: true
+  # -- The max body size to allow. Requests exceeding this size will result
+  # in an 413 error being returned to the client.
+  # https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#custom-max-body-size
+  maxBodySize: 10m
+  # -- The fully-qualified hostname of the Ingress Resource.
+  host:
+  # -- The custom annotations that should be applied to the Ingress 
+  # Resource when not using the Kubernetes ingress-nginx controller.
+  annotations: {}
+  # -- True if the browser communicates with the application over HTTPS.
+  https: true
+  # -- Secret that contains a TLS private key and certificate.
+  # Optional if Ingress Controller is configured to use one secret for all ingresses
+  tlsSecretName:
+
+fluentd:
+  # -- True if the fluentd sidecar should be added to each pod
+  enabled: false
+  # -- True if a custom config should be used for fluentd
+  customConfigFile: false
+  # -- Custom fluent.conf file
+  # fluent.conf: |
+  fluentdCustomConfig: {}
+  # fluent.conf: |
+  #   <source>
+  #     @type tail
+  #     <parse>
+  #     @type multiline
+  #     format_firstline /\d{4}-\d{1,2}-\d{1,2}/
+  #     </parse>
+  #     path /opt/atlassian/confluence/logs/access_log.*
+  #     pos_file /tmp/confluencelog.pos
+  #     tag confluence-access-logs
+  #   </source>
+
+ # -- The name of the image containing the fluentd sidecar
+  imageName: fluent/fluentd-kubernetes-daemonset:v1.11.5-debian-elasticsearch7-1.2
+  # -- The port on which the fluentd sidecar will listen
+  httpPort: 9880
+  elasticsearch:
+    # -- True if fluentd should send all log events to an elasticsearch service.
+    enabled: true
+    # -- The hostname of the Elasticsearch service that fluentd should send logs to.
+    hostname: elasticsearch
+    # -- The prefix of the elasticsearch index name that will be used
+    indexNamePrefix: confluence
+  # -- Specify custom volumes to be added to fluentd container (e.g. more log sources)
+  extraVolumes: []
+  # - name: local-home
+  #   mountPath: /opt/atlassian/confluence/logs
+  #   subPath: log
+  #   readOnly: true
 # -- Specify additional annotations to be added to all Confluence and Synchrony pods
 podAnnotations: {}
 #  "name": "value"
 
 volumes:
   localHome:
-    # -- Specifies the name of the storage class that should be used for the Confluence local-home volume
-    storageClassName:
-    # -- Specifies the standard Kubernetes resource requests and/or limits for the Confluence local-home volume.
-    resources:
-      requests:
-        storage: 1Gi
-    # -- Specifies the path in the Confluence container to which the local-home volume will be mounted.
+    persistentVolumeClaim:
+      # -- If true, then a PersistentVolumeClaim will be created for each local-home volume.
+      create: false
+      # -- Specifies the name of the storage class that should be used for the local-home volume claim.
+      storageClassName:
+      # -- Specifies the standard Kubernetes resource requests and/or limits for the local-home volume claims.
+      resources:
+        requests:
+          storage: 1Gi
+    # -- When persistentVolumeClaim.create is false, then this value can be used to define a standard Kubernetes
+    # volume which will be used for the local-home volumes. If not defined, then defaults to an emptyDir volume.
+    customVolume: {}
+    # -- The path within the Confluence container which the local-home volume should be mounted.
     mountPath: "/var/atlassian/application-data/confluence"
   sharedHome:
+    persistentVolumeClaim:
+      # -- If true, then a PersistentVolumeClaim will be created for the shared-home volume.
+      create: false
+      # -- Specifies the name of the storage class that should be used for the shared-home volume claim.
+      storageClassName:
+      # -- Specifies the standard Kubernetes resource requests and/or limits for the shared-home volume claims.
+      resources:
+        requests:
+          storage: 1Gi
+    # -- When persistentVolumeClaim.create is false, then this value can be used to define a standard Kubernetes
+    # volume which will be used for the shared-home volume. If not defined, then defaults to an emptyDir (i.e. unshared) volume.
+    customVolume: {}
     # -- Specifies the path in the Confluence container to which the shared-home volume will be mounted.
     mountPath: "/var/atlassian/application-data/shared-home"
     # -- Specifies the sub-directory of the shared-home volume which will be mounted in to the Confluence container.
     subPath:
-    # -- The name of the PersistentVolumeClaim which will be used for the shared-home volume
-    volumeClaimName: confluence-shared-home
     nfsPermissionFixer:
       # -- If enabled, this will alter the shared-home volume's root directory so that Confluence can write to it.
       # This is a workaround for a Kubernetes bug affecting NFS volumes: https://github.com/kubernetes/examples/issues/260
-      enabled: true
+      enabled: false
       # -- The path in the initContainer where the shared-home volume will be mounted
       mountPath: /shared-home
       # -- By default, the fixer will change the group ownership of the volume's root directory to match the Confluence
       # container's GID (2002), and then ensures the directory is group-writeable. If this is not the desired behaviour,
       # command used can be specified here.
       command:
+  # -- Defines additional volumes that should be applied to all Confluence pods.
+  # Note that this will not create any corresponding volume mounts;
+  # those needs to be defined in confluence.additionalVolumeMounts
+  additional: []
 
 # -- Standard Kubernetes node-selectors that will be applied to all Confluence and Synchrony pods
 nodeSelector: {}
@@ -163,3 +308,26 @@ additionalContainers: []
 
 # -- Additional initContainer definitions that will be added to all Confluence pods
 additionalInitContainers: []
+
+# -- Additional labels that should be applied to all resources
+additionalLabels: {}
+
+# -- Additional existing ConfigMaps and Secrets not managed by Helm that should be mounted into server container
+# configMap and secret are two available types (camelCase is important!)
+# mountPath is a destination directory in a container and key is file name
+# name references existing ConfigMap or secret name. VolumeMount and Volumes are added with this name + index position,
+# for example custom-config-0, keystore-2
+additionalFiles: []
+
+#  - name: custom-config
+#    type: configMap
+#    key: log4j.properties
+#    mountPath:  /var/atlassian
+#  - name: custom-config
+#    type: configMap
+#    key: web.xml
+#    mountPath: /var/atlassian
+#  - name: keystore
+#    type: secret
+#    key: keystore.jks
+#    mountPath: /var/ssl
```

## 0.1.0 

**Release date:** 2020-11-04

![AppVersion: 7.9.0-beta1-jdk11](https://img.shields.io/static/v1?label=AppVersion&message=7.9.0-beta1-jdk11&color=success&logo=)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)


* OSR-523 Snapshot of helm charts and test code from internal repo 

### Default value changes

```diff
# -- The initial number of pods that should be started at deployment of each of Confluence and Synchrony.
# Note that because Confluence requires initial manual configuration after the first pod is deployed, and before scaling
# up to additional pods, this should always be kept as 1.
replicaCount: 1

image:
  repository: atlassian/confluence-server
  pullPolicy: IfNotPresent
  # -- The docker image tag to be used. Defaults to the Chart appVersion.
  tag:

# -- Specifies which serviceAccount to use for the pods. If not specified, the kubernetes default will be used.
serviceAccountName:

database:
  # -- The type of database being used.
  # Valid values include 'postgresql', 'mysql', 'oracle', 'mssql'.
  type:
  # -- The JDBC URL of the database to be used by Confluence and Synchrony, e.g. jdbc:postgresql://host:port/database
  url:
  credentials:
    # -- The name of the Kubernetes Secret that contains the database login credentials.
    secretName: confluence-database-credentials
    # -- The key in the Secret used to store the database login username
    usernameSecretKey: username
    # -- The key in the Secret used to store the database login password
    passwordSecretKey: password

confluence:
  service:
    # -- The port on which the Confluence Kubernetes service will listen
    port: 80
    # -- The type of Kubernetes service to use for Confluence
    type: ClusterIP
  # -- The GID used by the Confluence docker image
  gid: "2002"
  ports:
    # -- The port on which the Confluence container listens for HTTP traffic
    http: 8090
    # -- The port on which the Confluence container listens for Hazelcast traffic
    hazelcast: 5701
  license:
    # -- The name of the Kubernetes Secret which contains the Confluence license key
    secretName: confluence-license
    # -- The key in the Kubernetes Secret which contains the Confluence license key
    secretKey: license-key
  readinessProbe:
    # -- The initial delay (in seconds) for the Confluence container readiness probe, after which the probe will start running
    initialDelaySeconds: 10
    # -- How often (in seconds) the Confluence container readiness robe will run
    periodSeconds: 5
    # -- The number of consecutive failures of the Confluence container readiness probe before the pod fails readiness checks
    failureThreshold: 30
  resources:
    jvm:
      # -- The maximum amount of heap memory that will be used by the Confluence JVM
      maxHeap: "1g"
      # -- The minimum amount of heap memory that will be used by the Confluence JVM
      minHeap: "1g"
      # -- The memory reserved for the Confluence JVM code cache
      reservedCodeCache: "512m"
    # -- Specifies the standard Kubernetes resource requests and/or limits for the Confluence container.
    # It is important that if the memory resources are specified here, they must allow for the size of the Confluence JVM.
    # That means the maximum heap size, the reserved code cache size, plus other JVM overheads, must be accommodated.
    # Allowing for (maxHeap+codeCache)*1.5 would be an example.
    container: {}
    #  limits:
    #    cpu: "4"
    #    memory: "2G"
    #  requests:
    #    cpu: "4"
    #    memory: "2G"

  # -- Specifies a list of additional arguments that can be passed to the Confluence JVM, e.g. system properties
  additionalJvmArgs: []
#    - -Dfoo=bar
#    - -Dfruit=lemon

  # -- Specifies a list of additional Java libraries that should be added to the Confluence container.
  # Each item in the list should specify the name of the volume which contain the library, as well as the name of the
  # library file within that volume's root directory. Optionally, a subDirectory field can be included to specify which
  # directory in the volume contains the library file.
  additionalLibraries: []
#    - volumeName:
#      subDirectory:
#      fileName:

  # -- Specifies a list of additional Confluence plugins that should be added to the Confluence container.
  # These are specified in the same manner as the additionalLibraries field, but the files will be loaded
  # as bundled plugins rather than as libraries.
  additionalBundledPlugins: []
#    - volumeName:
#      subDirectory:
#      fileName:

synchrony:
  service:
    # -- The port on which the Synchrony Kubernetes service will listen
    port: 80
    # -- The type of Kubernetes service to use for Synchrony
    type: ClusterIP
  ports:
    # -- The port on which the Synchrony container listens for HTTP traffic
    http: 8091
    # -- The port on which the Synchrony container listens for Hazelcast traffic
    hazelcast: 5701
  readinessProbe:
    # -- The initial delay (in seconds) for the Synchrony container readiness probe, after which the probe will start running
    initialDelaySeconds: 5
    # -- How often (in seconds) the Synchrony container readiness robe will run
    periodSeconds: 1
    # -- The number of consecutive failures of the Synchrony container readiness probe before the pod fails readiness checks
    failureThreshold: 30
  # -- The base URL of the Synchrony service.
  # This will be the URL that users' browsers will be given to communicate with Synchrony, as well as the URL that the
  # Confluence service will use to communicate directly with Synchrony, so the URL must be resovable both from inside and
  # outside the Kubernetes cluster.
  ingressUrl:

# -- Specify additional annotations to be added to all Confluence and Synchrony pods
podAnnotations: {}
#  "name": "value"

volumes:
  localHome:
    # -- Specifies the name of the storage class that should be used for the Confluence local-home volume
    storageClassName:
    # -- Specifies the standard Kubernetes resource requests and/or limits for the Confluence local-home volume.
    resources:
      requests:
        storage: 1Gi
    # -- Specifies the path in the Confluence container to which the local-home volume will be mounted.
    mountPath: "/var/atlassian/application-data/confluence"
  sharedHome:
    # -- Specifies the path in the Confluence container to which the shared-home volume will be mounted.
    mountPath: "/var/atlassian/application-data/shared-home"
    # -- Specifies the sub-directory of the shared-home volume which will be mounted in to the Confluence container.
    subPath:
    # -- The name of the PersistentVolumeClaim which will be used for the shared-home volume
    volumeClaimName: confluence-shared-home
    nfsPermissionFixer:
      # -- If enabled, this will alter the shared-home volume's root directory so that Confluence can write to it.
      # This is a workaround for a Kubernetes bug affecting NFS volumes: https://github.com/kubernetes/examples/issues/260
      enabled: true
      # -- The path in the initContainer where the shared-home volume will be mounted
      mountPath: /shared-home
      # -- By default, the fixer will change the group ownership of the volume's root directory to match the Confluence
      # container's GID (2002), and then ensures the directory is group-writeable. If this is not the desired behaviour,
      # command used can be specified here.
      command:

# -- Standard Kubernetes node-selectors that will be applied to all Confluence and Synchrony pods
nodeSelector: {}

# -- Standard Kubernetes tolerations that will be applied to all Confluence and Synchrony pods
tolerations: []

# -- Standard Kubernetes affinities that will be applied to all Confluence and Synchrony pods
affinity: {}

# -- Additional container definitions that will be added to all Confluence pods
additionalContainers: []

# -- Additional initContainer definitions that will be added to all Confluence pods
additionalInitContainers: []
```

---
Autogenerated from Helm Chart and git history using [helm-changelog](https://github.com/mogensen/helm-changelog)
