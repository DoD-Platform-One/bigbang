{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "common.names.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "common.names.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Kubernetes standard labels
*/}}
{{- define "common.labels.standard" -}}
app.kubernetes.io/name: {{ include "common.names.name" . }}
helm.sh/chart: {{ include "common.names.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Labels to use on deploy.spec.selector.matchLabels and svc.spec.selector
*/}}
{{- define "common.labels.matchLabels" -}}
app.kubernetes.io/name: {{ include "common.names.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Renders a value that contains template.
Usage:
{{ include "common.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "common.tplvalues.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "common.names.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper image name
{{ include "common.images.image" ( dict "imageRoot" .Values.path.to.the.image "global" $) }}
*/}}
{{- define "common.images.image" -}}
{{- $registryName := .imageRoot.registry -}}
{{- $repositoryName := .imageRoot.repository -}}
{{- $tag := .imageRoot.tag | toString -}}
{{- if .global }}
    {{- if .global.imageRegistry }}
     {{- $registryName = .global.imageRegistry -}}
    {{- end -}}
{{- end -}}
{{- if $registryName }}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- else -}}
{{- printf "%s:%s" $repositoryName $tag -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
{{ include "common.images.pullSecrets" ( dict "images" (list .Values.path.to.the.image1, .Values.path.to.the.image2) "global" .Values.global) }}
*/}}
{{- define "common.images.pullSecrets" -}}
  {{- $pullSecrets := list }}

  {{- if .global }}
    {{- range .global.imagePullSecrets -}}
      {{- $pullSecrets = append $pullSecrets . -}}
    {{- end -}}
  {{- end -}}

  {{- range .images -}}
    {{- range .pullSecrets -}}
      {{- $pullSecrets = append $pullSecrets . -}}
    {{- end -}}
  {{- end -}}

  {{- if (not (empty $pullSecrets)) }}
imagePullSecrets:
    {{- range $pullSecrets }}
  - name: {{ . }}
    {{- end }}
  {{- end }}
{{- end -}}

{{/*
Return a soft nodeAffinity definition 
{{ include "common.affinities.nodes.soft" (dict "key" "FOO" "values" (list "BAR" "BAZ")) -}}
*/}}
{{- define "common.affinities.nodes.soft" -}}
preferredDuringSchedulingIgnoredDuringExecution:
  - preference:
      matchExpressions:
        - key: {{ .key }}
          operator: In
          values:
            {{- range .values }}
            - {{ . }}
            {{- end }}
    weight: 1
{{- end -}}

{{/*
Return a hard nodeAffinity definition
{{ include "common.affinities.nodes.hard" (dict "key" "FOO" "values" (list "BAR" "BAZ")) -}}
*/}}
{{- define "common.affinities.nodes.hard" -}}
requiredDuringSchedulingIgnoredDuringExecution:
  nodeSelectorTerms:
    - matchExpressions:
        - key: {{ .key }}
          operator: In
          values:
            {{- range .values }}
            - {{ . }}
            {{- end }}
{{- end -}}

{{/*
Return a nodeAffinity definition
{{ include "common.affinities.nodes" (dict "type" "soft" "key" "FOO" "values" (list "BAR" "BAZ")) -}}
*/}}
{{- define "common.affinities.nodes" -}}
  {{- if eq .type "soft" }}
    {{- include "common.affinities.nodes.soft" . -}}
  {{- else if eq .type "hard" }}
    {{- include "common.affinities.nodes.hard" . -}}
  {{- end -}}
{{- end -}}

{{/*
Return a soft podAffinity/podAntiAffinity definition
{{ include "common.affinities.pods.soft" (dict "component" "FOO" "context" $) -}}
*/}}
{{- define "common.affinities.pods.soft" -}}
{{- $component := default "" .component -}}
preferredDuringSchedulingIgnoredDuringExecution:
  - podAffinityTerm:
      labelSelector:
        matchLabels: {{- (include "common.labels.matchLabels" .context) | nindent 10 }}
          {{- if not (empty $component) }}
          {{ printf "app.kubernetes.io/component: %s" $component }}
          {{- end }}
      namespaces:
        - {{ .context.Release.Namespace | quote }}
      topologyKey: kubernetes.io/hostname
    weight: 1
{{- end -}}

{{/*
Return a hard podAffinity/podAntiAffinity definition
{{ include "common.affinities.pods.hard" (dict "component" "FOO" "context" $) -}}
*/}}
{{- define "common.affinities.pods.hard" -}}
{{- $component := default "" .component -}}
requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchLabels: {{- (include "common.labels.matchLabels" .context) | nindent 8 }}
        {{- if not (empty $component) }}
        {{ printf "app.kubernetes.io/component: %s" $component }}
        {{- end }}
    namespaces:
      - {{ .context.Release.Namespace | quote }}
    topologyKey: kubernetes.io/hostname
{{- end -}}

{{/*
Return  the proper Storage Class
{{ include "common.storage.class" ( dict "persistence" .Values.path.to.the.persistence "global" $) }}
*/}}
{{- define "common.storage.class" -}}

{{- $storageClass := .persistence.storageClass -}}
{{- if .global -}}
    {{- if .global.storageClass -}}
        {{- $storageClass = .global.storageClass -}}
    {{- end -}}
{{- end -}}

{{- if $storageClass -}}
  {{- if (eq "-" $storageClass) -}}
      {{- printf "storageClassName: \"\"" -}}
  {{- else }}
      {{- printf "storageClassName: %s" $storageClass -}}
  {{- end -}}
{{- end -}}

{{- end -}}

{{/*
Warning about using rolling tag.
Usage:
{{ include "common.warnings.rollingTag" .Values.path.to.the.imageRoot }}
*/}}
{{- define "common.warnings.rollingTag" -}}

{{- if and (contains "bitnami/" .repository) (not (.tag | toString | regexFind "-r\\d+$|sha256:")) }}
WARNING: Rolling tag detected ({{ .repository }}:{{ .tag }}), please note that it is strongly recommended to avoid using rolling tags in a production environment.
+info https://docs.bitnami.com/containers/how-to/understand-rolling-tags-containers/
{{- end }}

{{- end -}}

{{/*
Return a podAffinity/podAntiAffinity definition
{{ include "common.affinities.pods" (dict "type" "soft" "key" "FOO" "values" (list "BAR" "BAZ")) -}}
*/}}
{{- define "common.affinities.pods" -}}
  {{- if eq .type "soft" }}
    {{- include "common.affinities.pods.soft" . -}}
  {{- else if eq .type "hard" }}
    {{- include "common.affinities.pods.hard" . -}}
  {{- end -}}
{{- end -}}

{{/*
Validate PostgreSQL required passwords are not empty.
Usage:
{{ include "common.validations.values.postgresql.passwords" (dict "secret" "secretName" "subchart" false "context" $) }}
Params:
  - secret - String - Required. Name of the secret where postgresql values are stored, e.g: "postgresql-passwords-secret"
  - subchart - Boolean - Optional. Whether postgresql is used as subchart or not. Default: false
*/}}
{{- define "common.validations.values.postgresql.passwords" -}}
  {{- $existingSecret := include "common.postgresql.values.existingSecret" . -}}
  {{- $enabled := include "common.postgresql.values.enabled" . -}}
  {{- $valueKeyPostgresqlPassword := include "common.postgresql.values.key.postgressPassword" . -}}
  {{- $valueKeyPostgresqlReplicationEnabled := include "common.postgresql.values.key.replicationPassword" . -}}

  {{- if and (not $existingSecret) (eq $enabled "true") -}}
    {{- $requiredPasswords := list -}}

    {{- $requiredPostgresqlPassword := dict "valueKey" $valueKeyPostgresqlPassword "secret" .secret "field" "postgresql-password" -}}
    {{- $requiredPasswords = append $requiredPasswords $requiredPostgresqlPassword -}}

    {{- $enabledReplication := include "common.postgresql.values.enabled.replication" . -}}
    {{- if (eq $enabledReplication "true") -}}
        {{- $requiredPostgresqlReplicationPassword := dict "valueKey" $valueKeyPostgresqlReplicationEnabled "secret" .secret "field" "postgresql-replication-password" -}}
        {{- $requiredPasswords = append $requiredPasswords $requiredPostgresqlReplicationPassword -}}
    {{- end -}}

    {{- include "common.validations.values.multiple.empty" (dict "required" $requiredPasswords "context" .context) -}}
  {{- end -}}
{{- end -}}

{{/*
Validate values must not be empty.
Usage:
{{- $validateValueConf00 := (dict "valueKey" "path.to.value" "secret" "secretName" "field" "password-00") -}}
{{- $validateValueConf01 := (dict "valueKey" "path.to.value" "secret" "secretName" "field" "password-01") -}}
{{ include "common.validations.values.empty" (dict "required" (list $validateValueConf00 $validateValueConf01) "context" $) }}

Validate value params:
  - valueKey - String - Required. The path to the validating value in the values.yaml, e.g: "mysql.password"
  - secret - String - Optional. Name of the secret where the validating value is generated/stored, e.g: "mysql-passwords-secret"
  - field - String - Optional. Name of the field in the secret data, e.g: "mysql-password"
*/}}
{{- define "common.validations.values.multiple.empty" -}}
  {{- range .required -}}
    {{- include "common.validations.values.single.empty" (dict "valueKey" .valueKey "secret" .secret "field" .field "context" $.context) -}}
  {{- end -}}
{{- end -}}

{{/*
Validate a value must not be empty.
Usage:
{{ include "common.validations.value.empty" (dict "valueKey" "mariadb.password" "secret" "secretName" "field" "my-password" "subchart" "subchart" "context" $) }}

Validate value params:
  - valueKey - String - Required. The path to the validating value in the values.yaml, e.g: "mysql.password"
  - secret - String - Optional. Name of the secret where the validating value is generated/stored, e.g: "mysql-passwords-secret"
  - field - String - Optional. Name of the field in the secret data, e.g: "mysql-password"
  - subchart - String - Optional - Name of the subchart that the validated password is part of.
*/}}
{{- define "common.validations.values.single.empty" -}}
  {{- $value := include "common.utils.getValueFromKey" (dict "key" .valueKey "context" .context) }}
  {{- $subchart := ternary "" (printf "%s." .subchart) (empty .subchart) }}

  {{- if not $value -}}
    {{- $varname := "my-value" -}}
    {{- $getCurrentValue := "" -}}
    {{- if and .secret .field -}}
      {{- $varname = include "common.utils.fieldToEnvVar" . -}}
      {{- $getCurrentValue = printf " To get the current value:\n\n        %s\n" (include "common.utils.secret.getvalue" .) -}}
    {{- end -}}
    {{- printf "\n    '%s' must not be empty, please add '--set %s%s=$%s' to the command.%s" .valueKey $subchart .valueKey $varname $getCurrentValue -}}
  {{- end -}}
{{- end -}}

{{/*
Print instructions to get a secret value.
Usage:
{{ include "common.utils.secret.getvalue" (dict "secret" "secret-name" "field" "secret-value-field" "context" $) }}
*/}}
{{- define "common.utils.secret.getvalue" -}}
{{- $varname := include "common.utils.fieldToEnvVar" . -}}
export {{ $varname }}=$(kubectl get secret --namespace {{ .context.Release.Namespace | quote }} {{ .secret }} -o jsonpath="{.data.{{ .field }}}" | base64 --decode)
{{- end -}}

{{/*
Build env var name given a field
Usage:
{{ include "common.utils.fieldToEnvVar" dict "field" "my-password" }}
*/}}
{{- define "common.utils.fieldToEnvVar" -}}
  {{- $fieldNameSplit := splitList "-" .field -}}
  {{- $upperCaseFieldNameSplit := list -}}

  {{- range $fieldNameSplit -}}
    {{- $upperCaseFieldNameSplit = append $upperCaseFieldNameSplit ( upper . ) -}}
  {{- end -}}

  {{ join "_" $upperCaseFieldNameSplit }}
{{- end -}}

{{/*
Gets a value from .Values given
Usage:
{{ include "common.utils.getValueFromKey" (dict "key" "path.to.key" "context" $) }}
*/}}
{{- define "common.utils.getValueFromKey" -}}
{{- $splitKey := splitList "." .key -}}
{{- $value := "" -}}
{{- $latestObj := $.context.Values -}}
{{- range $splitKey -}}
  {{- if not $latestObj -}}
    {{- printf "please review the entire path of '%s' exists in values" $.key | fail -}}
  {{- end -}}
  {{- $value = ( index $latestObj . ) -}}
  {{- $latestObj = $value -}}
{{- end -}}
{{- printf "%v" (default "" $value) -}} 
{{- end -}}

{{/*
Returns first .Values key with a defined value or first of the list if all non-defined
Usage:
{{ include "common.utils.getKeyFromList" (dict "keys" (list "path.to.key1" "path.to.key2") "context" $) }}
*/}}
{{- define "common.utils.getKeyFromList" -}}
{{- $key := first .keys -}}
{{- $reverseKeys := reverse .keys }}
{{- range $reverseKeys }}
  {{- $value := include "common.utils.getValueFromKey" (dict "key" . "context" $.context ) }}
  {{- if $value -}}
    {{- $key = . }}
  {{- end -}}
{{- end -}}
{{- printf "%s" $key -}} 
{{- end -}}

{{/*
Auxiliary function to decide whether evaluate global values.
Usage:
{{ include "common.postgresql.values.use.global" (dict "key" "key-of-global" "context" $) }}
Params:
  - key - String - Required. Field to be evaluated within global, e.g: "existingSecret"
*/}}
{{- define "common.postgresql.values.use.global" -}}
  {{- if .context.Values.global -}}
    {{- if .context.Values.global.postgresql -}}
      {{- index .context.Values.global.postgresql .key | quote -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Auxiliary function to get the right value for existingSecret.
Usage:
{{ include "common.postgresql.values.existingSecret" (dict "context" $) }}
*/}}
{{- define "common.postgresql.values.existingSecret" -}}
  {{- $globalValue := include "common.postgresql.values.use.global" (dict "key" "existingSecret" "context" .context) -}}

  {{- if .subchart -}}
    {{- default (.context.Values.postgresql.existingSecret | quote) $globalValue -}}
  {{- else -}}
    {{- default (.context.Values.existingSecret | quote) $globalValue -}}
  {{- end -}}
{{- end -}}

{{/*
Auxiliary function to get the right value for enabled postgresql.
Usage:
{{ include "common.postgresql.values.enabled" (dict "context" $) }}
*/}}
{{- define "common.postgresql.values.enabled" -}}
  {{- if .subchart -}}
    {{- printf "%v" .context.Values.postgresql.enabled -}}
  {{- else -}}
    {{- printf "%v" (not .context.Values.enabled) -}}
  {{- end -}}
{{- end -}}

{{/*
Auxiliary function to get the right value for the key postgressPassword.
Usage:
{{ include "common.postgresql.values.key.postgressPassword" (dict "subchart" "true" "context" $) }}
Params:
  - subchart - Boolean - Optional. Whether postgresql is used as subchart or not. Default: false
*/}}
{{- define "common.postgresql.values.key.postgressPassword" -}}
  {{- $globalValue := include "common.postgresql.values.use.global" (dict "key" "postgresqlUsername" "context" .context) -}}

  {{- if not $globalValue -}}
    {{- if .subchart -}}
      postgresql.postgresqlPassword
    {{- else -}}
      postgresqlPassword
    {{- end -}}
  {{- else -}}
    global.postgresql.postgresqlPassword
  {{- end -}}
{{- end -}}

{{/*
Auxiliary function to get the right value for enabled.replication.
Usage:
{{ include "common.postgresql.values.enabled.replication" (dict "subchart" "true" "context" $) }}
Params:
  - subchart - Boolean - Optional. Whether postgresql is used as subchart or not. Default: false
*/}}
{{- define "common.postgresql.values.enabled.replication" -}}
  {{- if .subchart -}}
    {{- printf "%v" .context.Values.postgresql.replication.enabled -}}
  {{- else -}}
    {{- printf "%v" .context.Values.replication.enabled -}}
  {{- end -}}
{{- end -}}

{{/*
Auxiliary function to get the right value for the key replication.password.
Usage:
{{ include "common.postgresql.values.key.replicationPassword" (dict "subchart" "true" "context" $) }}
Params:
  - subchart - Boolean - Optional. Whether postgresql is used as subchart or not. Default: false
*/}}
{{- define "common.postgresql.values.key.replicationPassword" -}}
  {{- if .subchart -}}
    postgresql.replication.password
  {{- else -}}
    replication.password
  {{- end -}}
{{- end -}}

{{/*
Through error when upgrading using empty passwords values that must not be empty.
Usage:
{{- $validationError00 := include "common.validations.values.single.empty" (dict "valueKey" "path.to.password00" "secret" "secretName" "field" "password-00") -}}
{{- $validationError01 := include "common.validations.values.single.empty" (dict "valueKey" "path.to.password01" "secret" "secretName" "field" "password-01") -}}
{{ include "common.errors.upgrade.passwords.empty" (dict "validationErrors" (list $validationError00 $validationError01) "context" $) }}

Required password params:
  - validationErrors - String - Required. List of validation strings to be return, if it is empty it won't throw error.
  - context - Context - Required. Parent context.
*/}}
{{- define "common.errors.upgrade.passwords.empty" -}}
  {{- $validationErrors := join "" .validationErrors -}}
  {{- if and $validationErrors .context.Release.IsUpgrade -}}
    {{- $errorString := "\nPASSWORDS ERROR: you must provide your current passwords when upgrade the release%s" -}}
    {{- printf $errorString $validationErrors | fail -}}
  {{- end -}}
{{- end -}}

{{/*
Return the target Kubernetes version
*/}}
{{- define "common.capabilities.kubeVersion" -}}
{{- if .Values.global }}
    {{- if .Values.global.kubeVersion }}
    {{- .Values.global.kubeVersion -}}
    {{- else }}
    {{- default .Capabilities.KubeVersion.Version .Values.kubeVersion -}}
    {{- end -}}
{{- else }}
{{- default .Capabilities.KubeVersion.Version .Values.kubeVersion -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for deployment.
*/}}
{{- define "common.capabilities.deployment.apiVersion" -}}
{{- if semverCompare "<1.14-0" (include "common.capabilities.kubeVersion" .) -}}
{{- print "extensions/v1beta1" -}}
{{- else -}}
{{- print "apps/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for statefulset.
*/}}
{{- define "common.capabilities.statefulset.apiVersion" -}}
{{- if semverCompare "<1.14-0" (include "common.capabilities.kubeVersion" .) -}}
{{- print "apps/v1beta1" -}}
{{- else -}}
{{- print "apps/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for ingress.
*/}}
{{- define "common.capabilities.ingress.apiVersion" -}}
{{- if .Values.ingress -}}
{{- if .Values.ingress.apiVersion -}}
{{- .Values.ingress.apiVersion -}}
{{- else if semverCompare "<1.14-0" (include "common.capabilities.kubeVersion" .) -}}
{{- print "extensions/v1beta1" -}}
{{- else if semverCompare "<1.19-0" (include "common.capabilities.kubeVersion" .) -}}
{{- print "networking.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "networking.k8s.io/v1" -}}
{{- end }}
{{- else if semverCompare "<1.14-0" (include "common.capabilities.kubeVersion" .) -}}
{{- print "extensions/v1beta1" -}}
{{- else if semverCompare "<1.19-0" (include "common.capabilities.kubeVersion" .) -}}
{{- print "networking.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "networking.k8s.io/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for RBAC resources.
*/}}
{{- define "common.capabilities.rbac.apiVersion" -}}
{{- if semverCompare "<1.17-0" (include "common.capabilities.kubeVersion" .) -}}
{{- print "rbac.authorization.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "rbac.authorization.k8s.io/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for CRDs.
*/}}
{{- define "common.capabilities.crd.apiVersion" -}}
{{- if semverCompare "<1.19-0" (include "common.capabilities.kubeVersion" .) -}}
{{- print "apiextensions.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "apiextensions.k8s.io/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Returns true if the used Helm version is 3.3+.
A way to check the used Helm version was not introduced until version 3.3.0 with .Capabilities.HelmVersion, which contains an additional "{}}"  structure.
This check is introduced as a regexMatch instead of {{ if .Capabilities.HelmVersion }} because checking for the key HelmVersion in <3.3 results in a "interface not found" error.
**To be removed when the catalog's minimun Helm version is 3.3**
*/}}
{{- define "common.capabilities.supportsHelmVersion" -}}
{{- if regexMatch "{(v[0-9])*[^}]*}}$" (.Capabilities | toString ) }}
  {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "postgresql.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "postgresql.primary.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- $fullname := default (printf "%s-%s" .Release.Name $name) .Values.fullnameOverride -}}
{{- if .Values.replication.enabled -}}
{{- printf "%s-%s" $fullname "primary" | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" $fullname | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper PostgreSQL image name
*/}}
{{- define "postgresql.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper PostgreSQL metrics image name
*/}}
{{- define "postgresql.metrics.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.metrics.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper image name (for the init container volume-permissions image)
*/}}
{{- define "postgresql.volumePermissions.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.volumePermissions.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "postgresql.imagePullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.image .Values.metrics.image .Values.volumePermissions.image) "global" .Values.global) }}
{{- end -}}

{{/*
Return PostgreSQL postgres user password
*/}}
{{- define "postgresql.postgres.password" -}}
{{- if .Values.global.postgresql.postgresqlPostgresPassword }}
    {{- .Values.global.postgresql.postgresqlPostgresPassword -}}
{{- else if .Values.postgresqlPostgresPassword -}}
    {{- .Values.postgresqlPostgresPassword -}}
{{- else -}}
    {{- randAlphaNum 10 -}}
{{- end -}}
{{- end -}}

{{/*
Return PostgreSQL password
*/}}
{{- define "postgresql.password" -}}
{{- if .Values.global.postgresql.postgresqlPassword }}
    {{- .Values.global.postgresql.postgresqlPassword -}}
{{- else if .Values.postgresqlPassword -}}
    {{- .Values.postgresqlPassword -}}
{{- else -}}
    {{- randAlphaNum 10 -}}
{{- end -}}
{{- end -}}

{{/*
Return PostgreSQL replication password
*/}}
{{- define "postgresql.replication.password" -}}
{{- if .Values.global.postgresql.replicationPassword }}
    {{- .Values.global.postgresql.replicationPassword -}}
{{- else if .Values.replication.password -}}
    {{- .Values.replication.password -}}
{{- else -}}
    {{- randAlphaNum 10 -}}
{{- end -}}
{{- end -}}

{{/*
Return PostgreSQL username
*/}}
{{- define "postgresql.username" -}}
{{- if .Values.global.postgresql.postgresqlUsername }}
    {{- .Values.global.postgresql.postgresqlUsername -}}
{{- else -}}
    {{- .Values.postgresqlUsername -}}
{{- end -}}
{{- end -}}

{{/*
Return PostgreSQL replication username
*/}}
{{- define "postgresql.replication.username" -}}
{{- if .Values.global.postgresql.replicationUser }}
    {{- .Values.global.postgresql.replicationUser -}}
{{- else -}}
    {{- .Values.replication.user -}}
{{- end -}}
{{- end -}}

{{/*
Return PostgreSQL port
*/}}
{{- define "postgresql.port" -}}
{{- if .Values.global.postgresql.servicePort }}
    {{- .Values.global.postgresql.servicePort -}}
{{- else -}}
    {{- .Values.service.port -}}
{{- end -}}
{{- end -}}

{{/*
Return PostgreSQL created database
*/}}
{{- define "postgresql.database" -}}
{{- if .Values.global.postgresql.postgresqlDatabase }}
    {{- .Values.global.postgresql.postgresqlDatabase -}}
{{- else if .Values.postgresqlDatabase -}}
    {{- .Values.postgresqlDatabase -}}
{{- end -}}
{{- end -}}

{{/*
Get the password secret.
*/}}
{{- define "postgresql.secretName" -}}
{{- if .Values.global.postgresql.existingSecret }}
    {{- printf "%s" (tpl .Values.global.postgresql.existingSecret $) -}}
{{- else if .Values.existingSecret -}}
    {{- printf "%s" (tpl .Values.existingSecret $) -}}
{{- else -}}
    {{- printf "%s" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if we should use an existingSecret.
*/}}
{{- define "postgresql.useExistingSecret" -}}
{{- if or .Values.global.postgresql.existingSecret .Values.existingSecret -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a secret object should be created
*/}}
{{- define "postgresql.createSecret" -}}
{{- if not (include "postgresql.useExistingSecret" .) -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Get the configuration ConfigMap name.
*/}}
{{- define "postgresql.configurationCM" -}}
{{- if .Values.configurationConfigMap -}}
{{- printf "%s" (tpl .Values.configurationConfigMap $) -}}
{{- else -}}
{{- printf "%s-configuration" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Get the extended configuration ConfigMap name.
*/}}
{{- define "postgresql.extendedConfigurationCM" -}}
{{- if .Values.extendedConfConfigMap -}}
{{- printf "%s" (tpl .Values.extendedConfConfigMap $) -}}
{{- else -}}
{{- printf "%s-extended-configuration" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a configmap should be mounted with PostgreSQL configuration
*/}}
{{- define "postgresql.mountConfigurationCM" -}}
{{- if or (.Files.Glob "files/postgresql.conf") (.Files.Glob "files/pg_hba.conf") .Values.postgresqlConfiguration .Values.pgHbaConfiguration .Values.configurationConfigMap }}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Get the initialization scripts ConfigMap name.
*/}}
{{- define "postgresql.initdbScriptsCM" -}}
{{- if .Values.initdbScriptsConfigMap -}}
{{- printf "%s" (tpl .Values.initdbScriptsConfigMap $) -}}
{{- else -}}
{{- printf "%s-init-scripts" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Get the initialization scripts Secret name.
*/}}
{{- define "postgresql.initdbScriptsSecret" -}}
{{- printf "%s" (tpl .Values.initdbScriptsSecret $) -}}
{{- end -}}

{{/*
Get the metrics ConfigMap name.
*/}}
{{- define "postgresql.metricsCM" -}}
{{- printf "%s-metrics" (include "common.names.fullname" .) -}}
{{- end -}}

{{/*
Get the readiness probe command
*/}}
{{- define "postgresql.readinessProbeCommand" -}}
- |
{{- if (include "postgresql.database" .) }}
  exec pg_isready -U {{ include "postgresql.username" . | quote }} -d "dbname={{ include "postgresql.database" . }} {{- if and .Values.tls.enabled .Values.tls.certCAFilename }} sslcert={{ include "postgresql.tlsCert" . }} sslkey={{ include "postgresql.tlsCertKey" . }}{{- end }}" -h 127.0.0.1 -p {{ template "postgresql.port" . }}
{{- else }}
  exec pg_isready -U {{ include "postgresql.username" . | quote }} {{- if and .Values.tls.enabled .Values.tls.certCAFilename }} -d "sslcert={{ include "postgresql.tlsCert" . }} sslkey={{ include "postgresql.tlsCertKey" . }}"{{- end }} -h 127.0.0.1 -p {{ template "postgresql.port" . }}
{{- end }}
{{- if contains "bitnami/" .Values.image.repository }}
  [ -f /opt/bitnami/postgresql/tmp/.initialized ] || [ -f /bitnami/postgresql/.initialized ]
{{- end -}}
{{- end -}}

{{/*
Compile all warnings into a single message, and call fail.
*/}}
{{- define "postgresql.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "postgresql.validateValues.ldapConfigurationMethod" .) -}}
{{- $messages := append $messages (include "postgresql.validateValues.psp" .) -}}
{{- $messages := append $messages (include "postgresql.validateValues.tls" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{- printf "\nVALUES VALIDATION:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}

{{/*
Validate values of Postgresql - If ldap.url is used then you don't need the other settings for ldap
*/}}
{{- define "postgresql.validateValues.ldapConfigurationMethod" -}}
{{- if and .Values.ldap.enabled (and (not (empty .Values.ldap.url)) (not (empty .Values.ldap.server))) }}
postgresql: ldap.url, ldap.server
    You cannot set both `ldap.url` and `ldap.server` at the same time.
    Please provide a unique way to configure LDAP.
    More info at https://www.postgresql.org/docs/current/auth-ldap.html
{{- end -}}
{{- end -}}

{{/*
Validate values of Postgresql - If PSP is enabled RBAC should be enabled too
*/}}
{{- define "postgresql.validateValues.psp" -}}
{{- if and .Values.psp.create (not .Values.rbac.create) }}
postgresql: psp.create, rbac.create
    RBAC should be enabled if PSP is enabled in order for PSP to work.
    More info at https://kubernetes.io/docs/concepts/policy/pod-security-policy/#authorizing-policies
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for podsecuritypolicy.
*/}}
{{- define "podsecuritypolicy.apiVersion" -}}
{{- if semverCompare "<1.10-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "extensions/v1beta1" -}}
{{- else -}}
{{- print "policy/v1beta1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for networkpolicy.
*/}}
{{- define "postgresql.networkPolicy.apiVersion" -}}
{{- if semverCompare ">=1.4-0, <1.7-0" .Capabilities.KubeVersion.GitVersion -}}
"extensions/v1beta1"
{{- else if semverCompare "^1.7-0" .Capabilities.KubeVersion.GitVersion -}}
"networking.k8s.io/v1"
{{- end -}}
{{- end -}}

{{/*
Validate values of Postgresql TLS - When TLS is enabled, so must be VolumePermissions
*/}}
{{- define "postgresql.validateValues.tls" -}}
{{- if and .Values.tls.enabled (not .Values.volumePermissions.enabled) }}
postgresql: tls.enabled, volumePermissions.enabled
    When TLS is enabled you must enable volumePermissions as well to ensure certificates files have
    the right permissions.
{{- end -}}
{{- end -}}

{{/*
Return the path to the cert file.
*/}}
{{- define "postgresql.tlsCert" -}}
{{- required "Certificate filename is required when TLS in enabled" .Values.tls.certFilename | printf "/opt/bitnami/postgresql/certs/%s" -}}
{{- end -}}

{{/*
Return the path to the cert key file.
*/}}
{{- define "postgresql.tlsCertKey" -}}
{{- required "Certificate Key filename is required when TLS in enabled" .Values.tls.certKeyFilename | printf "/opt/bitnami/postgresql/certs/%s" -}}
{{- end -}}

{{/*
Return the path to the CA cert file.
*/}}
{{- define "postgresql.tlsCACert" -}}
{{- printf "/opt/bitnami/postgresql/certs/%s" .Values.tls.certCAFilename -}}
{{- end -}}

{{/*
Return the path to the CRL file.
*/}}
{{- define "postgresql.tlsCRL" -}}
{{- if .Values.tls.crlFilename -}}
{{- printf "/opt/bitnami/postgresql/certs/%s" .Values.tls.crlFilename -}}
{{- end -}}
{{- end -}}
