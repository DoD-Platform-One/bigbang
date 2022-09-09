{{/* vim: set filetype=mustache: */}}
{{/*
Create default value for ingress port
*/}}
{{- define "confluence.ingressPort" -}}
{{ default (ternary "443" "80" .Values.ingress.https) .Values.ingress.port -}}
{{- end }}

{{/*
The name the synchrony app within the chart.
TODO: This will break if the common.names.name exceeds 63 characters, need to find a more rebust way to do this
*/}}
{{- define "synchrony.name" -}}
{{ include "common.names.name" . }}-synchrony
{{- end }}

{{/*
The full-qualfied name of the synchrony app within the chart.
TODO: This will break if the common.names.fullname exceeds 63 characters, need to find a more rebust way to do this
*/}}
{{- define "synchrony.fullname" -}}
{{ include "common.names.fullname" . }}-synchrony
{{- end }}

{{/*
The name of the service account to be used.
If the name is defined in the chart values, then use that,
else if we're creating a new service account then use the name of the Helm release,
else just use the "default" service account.
*/}}
{{- define "confluence.serviceAccountName" -}}
{{- if .Values.serviceAccount.name -}}
{{- .Values.serviceAccount.name -}}
{{- else -}}
{{- if .Values.serviceAccount.create -}}
{{- include "common.names.fullname" . -}}
{{- else -}}
default
{{- end -}}
{{- end -}}
{{- end }}

{{/*
The name of the ClusterRole that will be created.
If the name is defined in the chart values, then use that,
else use the name of the Helm release.
*/}}
{{- define "confluence.clusterRoleName" -}}
{{- if .Values.serviceAccount.clusterRole.name }}
{{- .Values.serviceAccount.clusterRole.name }}
{{- else }}
{{- include "common.names.fullname" . -}}
{{- end }}
{{- end }}

{{/*
The name of the ClusterRoleBinding that will be created.
If the name is defined in the chart values, then use that,
else use the name of the ClusterRole.
*/}}
{{- define "confluence.clusterRoleBindingName" -}}
{{- if .Values.serviceAccount.clusterRoleBinding.name }}
{{- .Values.serviceAccount.clusterRoleBinding.name }}
{{- else }}
{{- include "confluence.clusterRoleName" . -}}
{{- end }}
{{- end }}

{{/*
These labels will be applied to all Synchrony resources in the chart
*/}}
{{- define "synchrony.labels" -}}
helm.sh/chart: {{ include "common.names.chart" . }}
{{ include "synchrony.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ with .Values.additionalLabels }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels for finding Confluence (non-Synchrony) resources
*/}}
{{- define "confluence.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common.names.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels for finding Synchrony resources
*/}}
{{- define "synchrony.selectorLabels" -}}
app.kubernetes.io/name: {{ include "synchrony.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Pod labels
*/}}
{{- define "confluence.podLabels" -}}
{{ with .Values.podLabels }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{- define "confluence.sysprop.hazelcastListenPort" -}}
-Dconfluence.cluster.hazelcast.listenPort={{ .Values.confluence.ports.hazelcast }}
{{- end }}

{{- define "confluence.sysprop.clusterNodeName" -}}
-Dconfluence.clusterNodeName.useHostname={{ .Values.confluence.clustering.usePodNameAsClusterNodeName }}
{{- end }}

{{- define "confluence.sysprop.fluentdAppender" -}}
-Datlassian.logging.cloud.enabled={{.Values.fluentd.enabled}}
{{- end }}

{{- define "confluence.sysprop.debug" -}}
{{- if .Values.confluence.jvmDebug.enabled }} -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005 {{ end -}}
{{- end }}

{{- define "confluence.sysprop.enable.synchrony.by.default" -}}
-Dsynchrony.by.default.enable.collab.editing.if.manually.managed=true
{{- end -}}

{{- define "confluence.sysprop.synchronyServiceUrl" -}}
{{- if .Values.synchrony.enabled -}}
    {{- if .Values.ingress.https -}}-Dsynchrony.service.url=https://{{ .Values.ingress.host }}/synchrony/v1
    {{- else }}-Dsynchrony.service.url=http://{{ .Values.ingress.host }}/synchrony/v1
    {{- end }}
{{- else -}}
-Dsynchrony.btf.disabled=false
{{- end -}}
{{- end -}}

{{/*
Create default value for ingress path
*/}}
{{- define "confluence.ingressPath" -}}
{{- if .Values.ingress.path -}}
{{- .Values.ingress.path -}}
{{- else -}}
{{ default ( "/" ) .Values.confluence.service.contextPath -}}
{{- end }}
{{- end }}

{{/*
The command that should be run by the nfs-fixer init container to correct the permissions of the shared-home root directory.
*/}}
{{- define "sharedHome.permissionFix.command" -}}
{{- $securityContext := .Values.confluence.securityContext }}
{{- with .Values.volumes.sharedHome.nfsPermissionFixer }}
    {{- if .command }}
        {{ .command }}
    {{- else }}
        {{- if and $securityContext.gid $securityContext.enabled }}
            {{- printf "(chgrp %v %s; chmod g+w %s)" $securityContext.gid .mountPath .mountPath }}
        {{- else if $securityContext.fsGroup }}
            {{- printf "(chgrp %v %s; chmod g+w %s)" $securityContext.fsGroup .mountPath .mountPath }}
        {{- else }}
            {{- printf "(chgrp 2001 %s; chmod g+w %s)" .mountPath .mountPath }}
        {{- end }}
    {{- end }}
{{- end }}
{{- end }}

{{/*
The command that should be run to start the fluentd service
*/}}
{{- define "fluentd.start.command" -}}
{{- if .Values.fluentd.command }}
{{ .Values.fluentd.command }}
{{- else }}
{{- print "exec fluentd -c /fluentd/etc/fluent.conf -v" }}
{{- end }}
{{- end }}

{{- define "confluence.image" -}}
{{- if .Values.image.registry -}}
{{ .Values.image.registry}}/{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- else -}}
{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end }}
{{- end }}

{{/*
Defines the volume mounts used by the Confluence container.
Note that the local-home volume is mounted twice, once for the local-home directory itself, and again
on Tomcat's logs directory. THis ensures that Tomcat+Confluence logs get captured in the same volume.
*/}}
{{ define "confluence.volumeMounts" }}
- name: local-home
  mountPath: {{ .Values.volumes.localHome.mountPath | quote }}
- name: local-home
  mountPath: {{ .Values.confluence.accessLog.mountPath | quote }}
  subPath: {{ .Values.confluence.accessLog.localHomeSubPath | quote }}
- name: shared-home
  mountPath: {{ .Values.volumes.sharedHome.mountPath | quote }}
  {{- if .Values.volumes.sharedHome.subPath }}
  subPath: {{ .Values.volumes.sharedHome.subPath | quote }}
  {{- end }}
{{ end }}

{{/*
Defines the volume mounts used by the Synchrony container.
*/}}
{{ define "synchrony.volumeMounts" }}
- name: synchrony-home
  mountPath: {{ .Values.volumes.synchronyHome.mountPath | quote }}
{{ end }}

{{/*
For each additional library declared, generate a volume mount that injects that library into the Confluence lib directory
*/}}
{{- define "confluence.additionalLibraries" -}}
{{- range .Values.confluence.additionalLibraries }}
- name: {{ .volumeName }}
  mountPath: "/opt/atlassian/confluence/confluence/WEB-INF/lib/{{ .fileName }}"
  {{- if .subDirectory }}
  subPath: {{ printf "%s/%s" .subDirectory .fileName | quote }}
  {{- else }}
  subPath: {{ .fileName | quote }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
For each additional Synchrony library declared, generate a volume mount that injects that library into the Confluence lib directory
*/}}
{{- define "synchrony.additionalLibraries" -}}
{{- range .Values.synchrony.additionalLibraries }}
- name: {{ .volumeName }}
  mountPath: "/opt/atlassian/confluence/confluence/WEB-INF/lib/{{ .fileName }}"
  {{- if .subDirectory }}
  subPath: {{ printf "%s/%s" .subDirectory .fileName | quote }}
  {{- else }}
  subPath: {{ .fileName | quote }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Define pod annotations here to allow template overrides when used as a sub chart
*/}}
{{- define "confluence.podAnnotations" -}}
{{- with .Values.podAnnotations }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Define additional init containers here to allow template overrides when used as a sub chart
*/}}
{{- define "confluence.additionalInitContainers" -}}
{{- with .Values.additionalInitContainers }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Define additional hosts here to allow template overrides when used as a sub chart
*/}}
{{- define "confluence.additionalHosts" -}}
{{- with .Values.additionalHosts }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Define additional containers here to allow template overrides when used as a sub chart
*/}}
{{- define "confluence.additionalContainers" -}}
{{- with .Values.additionalContainers }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Define additional ports here instead of in values.yaml to allow template overrides
*/}}
{{- define "confluence.additionalPorts" -}}
{{- with .Values.confluence.additionalPorts }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Define additional ports here instead of in values.yaml to allow template overrides
*/}}
{{- define "synchrony.additionalPorts" -}}
{{- with .Values.synchrony.additionalPorts }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Define additional Confluence volume mounts here to allow template overrides when used as a sub chart
*/}}
{{- define "confluence.additionalVolumeMounts" -}}
{{- with .Values.confluence.additionalVolumeMounts }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Define additional Synchrony volume mounts here to allow template overrides when used as a sub chart
*/}}
{{- define "synchrony.additionalVolumeMounts" -}}
{{- with .Values.synchrony.additionalVolumeMounts }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Define additional environment variables here to allow template overrides when used as a sub chart
*/}}
{{- define "confluence.additionalEnvironmentVariables" -}}
{{- with .Values.confluence.additionalEnvironmentVariables }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
For each additional plugin declared, generate a volume mount that injects that library into the Confluence plugins directory
*/}}
{{- define "confluence.additionalBundledPlugins" -}}
{{- range .Values.confluence.additionalBundledPlugins }}
- name: {{ .volumeName }}
  mountPath: "/opt/atlassian/confluence/confluence/WEB-INF/atlassian-bundled-plugins/{{ .fileName }}"
  {{- if .subDirectory }}
  subPath: {{ printf "%s/%s" .subDirectory .fileName | quote }}
  {{- else }}
  subPath: {{ .fileName | quote }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "confluence.volumes" -}}
{{ if not .Values.volumes.localHome.persistentVolumeClaim.create }}
{{ include "confluence.volumes.localHome" . }}
{{- end }}
{{ include "confluence.volumes.sharedHome" . }}
{{- with .Values.volumes.additional }}
{{- toYaml . | nindent 0 }}
{{- end }}
{{- end }}

{{- define "synchrony.volumes" -}}
{{ if not .Values.volumes.synchronyHome.persistentVolumeClaim.create }}
{{ include "synchrony.volumes.synchronyHome" . }}
{{- end }}
{{ include "confluence.volumes.sharedHome" . }}
{{- with .Values.volumes.additionalSynchrony }}
{{- toYaml . | nindent 0 }}
{{- end }}
{{- end }}

{{- define "confluence.volumes.localHome" -}}
{{- if not .Values.volumes.localHome.persistentVolumeClaim.create }}
- name: local-home
{{ if .Values.volumes.localHome.customVolume }}
{{- toYaml .Values.volumes.localHome.customVolume | nindent 2 }}
{{ else }}
  emptyDir: {}
{{- end }}
{{- end }}
{{- end }}

{{- define "synchrony.volumes.synchronyHome" -}}
{{- if not .Values.volumes.synchronyHome.persistentVolumeClaim.create }}
- name: synchrony-home
{{ if .Values.volumes.synchronyHome.customVolume }}
{{- toYaml .Values.volumes.synchronyHome.customVolume | nindent 2 }}
{{ else }}
  emptyDir: {}
{{- end }}
{{- end }}
{{- end }}

{{- define "confluence.volumes.sharedHome" -}}
- name: shared-home
{{- if .Values.volumes.sharedHome.persistentVolumeClaim.create }}
  persistentVolumeClaim:
    claimName: {{ include "common.names.fullname" . }}-shared-home
{{ else }}
{{ if .Values.volumes.sharedHome.customVolume }}
{{- toYaml .Values.volumes.sharedHome.customVolume | nindent 2 }}
{{ else }}
  emptyDir: {}
{{- end }}
{{- end }}
{{- end }}

{{- define "confluence.volumeClaimTemplates" -}}
{{- if or .Values.volumes.localHome.persistentVolumeClaim.create .Values.confluence.additionalVolumeClaimTemplates }}
volumeClaimTemplates:
{{- if .Values.volumes.localHome.persistentVolumeClaim.create }}
- metadata:
    name: local-home
  spec:
    accessModes: [ "ReadWriteOnce" ]
    {{- if .Values.volumes.localHome.persistentVolumeClaim.storageClassName }}
    storageClassName: {{ .Values.volumes.localHome.persistentVolumeClaim.storageClassName | quote }}
    {{- end }}
    {{- with .Values.volumes.localHome.persistentVolumeClaim.resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
{{- end }}
{{- range .Values.confluence.additionalVolumeClaimTemplates }}
- metadata:
    name: {{ .name }}
  spec:
    accessModes: [ "ReadWriteOnce" ]
    {{- if .storageClassName }}
    storageClassName: {{ .storageClassName | quote }}
    {{- end }}
    {{- with .resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "synchrony.volumeClaimTemplates" -}}
{{ if .Values.volumes.synchronyHome.persistentVolumeClaim.create }}
volumeClaimTemplates:
- metadata:
    name: synchrony-home
  spec:
    accessModes: [ "ReadWriteOnce" ]
    {{- if .Values.volumes.synchronyHome.persistentVolumeClaim.storageClassName }}
    storageClassName: {{ .Values.volumes.synchronyHome.persistentVolumeClaim.storageClassName | quote }}
    {{- end }}
    {{- with .Values.volumes.synchronyHome.persistentVolumeClaim.resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
{{- end }}
{{- end }}

{{- define "confluence.databaseEnvVars" -}}
{{ with .Values.database.type }}
- name: ATL_DB_TYPE
  value: {{ . | quote }}
{{ end }}
{{ with .Values.database.url }}
- name: ATL_JDBC_URL
  value: {{ . | quote }}
{{ end }}
{{ with .Values.database.credentials.secretName }}
- name: ATL_JDBC_USER
  valueFrom:
    secretKeyRef:
      name: {{ . }}
      key: {{ $.Values.database.credentials.usernameSecretKey }}
- name: ATL_JDBC_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ . }}
      key: {{ $.Values.database.credentials.passwordSecretKey }}
{{ end }}
{{ end }}

{{- define "synchrony.databaseEnvVars" -}}
{{ with .Values.database.url }}
- name: SYNCHRONY_DATABASE_URL
  value: {{ . | quote }}
{{ end }}
{{ with .Values.database.credentials.secretName }}
- name: SYNCHRONY_DATABASE_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ . }}
      key: {{ $.Values.database.credentials.usernameSecretKey }}
- name: SYNCHRONY_DATABASE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ . }}
      key: {{ $.Values.database.credentials.passwordSecretKey }}
{{ end }}
{{ end }}

{{- define "confluence.clusteringEnvVars" -}}
{{ if .Values.confluence.clustering.enabled }}
- name: KUBERNETES_NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
- name: HAZELCAST_KUBERNETES_SERVICE_NAME
  value: {{ include "common.names.fullname" . | quote }}
- name: ATL_CLUSTER_TYPE
  value: "kubernetes"
- name: ATL_CLUSTER_NAME
  value: {{ include "common.names.fullname" . | quote }}
{{ end }}
{{ end }}

{{- define "synchrony.clusteringEnvVars" -}}
{{ if .Values.confluence.clustering.enabled }}
- name: KUBERNETES_NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
- name: HAZELCAST_KUBERNETES_SERVICE_NAME
  value: {{ include "synchrony.fullname" . | quote }}
- name: CLUSTER_JOIN_TYPE
  value: "kubernetes"
{{ end }}
{{ end }}

{{- define "flooredCPU" -}}
    {{- if hasSuffix "m" (. | toString) }}
    {{- div (trimSuffix "m" .) 1000 | default 1 }}
    {{- else }}
    {{- . }}
    {{- end }}
{{- end}}
