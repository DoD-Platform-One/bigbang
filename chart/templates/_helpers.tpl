{{/* vim: set filetype=mustache: */}}
{{/* Expand the name of the chart. */}}
{{- define "kyverno-policies.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Create chart name and version as used by the chart label. */}}
{{- define "kyverno-policies.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Helm required labels */}}
{{- define "kyverno-policies.labels" -}}
app.kubernetes.io/name: {{ template "kyverno-policies.name" . }}
helm.sh/chart: {{ template "kyverno-policies.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: "{{ .Chart.Version }}"
app.kubernetes.io/component: policy
app.kubernetes.io/part-of: kyverno
app: kyverno
{{- if .Values.customLabels }}
{{ toYaml .Values.customLabels }}
{{- end }}
{{- end -}}

{{/* Helm required labels */}}
{{- define "kyverno-policies.test-labels" -}}
app.kubernetes.io/name: {{ template "kyverno-policies.name" . }}-test
helm.sh/chart: {{ template "kyverno-policies.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: "{{ .Chart.Version }}"
app.kubernetes.io/component: policy
app.kubernetes.io/part-of: kyverno
{{- end -}}

{{/* WebhookTimeoutSeconds key/value.  Expects name of policy in .name */}}
{{- define "kyverno-policies.webhookTimeoutSeconds" -}}
{{- $webhookTimeoutSeconds := default .Values.webhookTimeoutSeconds (dig .name "webhookTimeoutSeconds" nil .Values.policies) -}}
{{- if $webhookTimeoutSeconds }}
webhookTimeoutSeconds: {{ $webhookTimeoutSeconds }}
{{- end }}
{{- end -}}

{{/* Match key/value.  Expects name of policy in .name and default kind in .kind as a list */}}
{{- define "kyverno-policies.match" -}}
{{- $policyMatch := (dig .name "match" nil .Values.policies) -}}
match:
  {{- if $policyMatch -}}
    {{- toYaml $policyMatch | nindent 2 -}}
  {{- else }}
  any:
  - resources:
      kinds:
      {{- toYaml .kinds | nindent 6 -}}
  {{- end -}}
{{- end -}}

{{/* Exclude key/value.  Expects name of policy in .name */}}
{{- define "kyverno-policies.exclude" -}}
{{- $globalExclude := .Values.exclude -}}
{{- $policyExclude := (dig .name "exclude" nil .Values.policies) -}}
{{- if or $globalExclude $policyExclude }}
exclude:
  any:
  {{- if $globalExclude -}}
    {{- if kindIs "map" $globalExclude -}}
      {{- toYaml $globalExclude.any | nindent 2 -}}
    {{- else -}}
      {{- toYaml $globalExclude | nindent 2 -}}
    {{- end -}}
  {{- end -}}
  {{- if $policyExclude -}}
    {{- if kindIs "map" $policyExclude -}}
        {{- toYaml $policyExclude.any | nindent 2 -}}
    {{- else -}}
        {{- toYaml $policyExclude | nindent 2 -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/* Add context for configMap to rule.  Expects name of policy in .name */}}
{{- define "kyverno-policies.context" -}}
{{- if (dig .name "parameters" nil .Values.policies) }}
context:
- name: configmap
  configMap:
    name: {{ .name }}
    namespace: {{ .Release.Namespace }}
{{- end }}
{{- end -}}

{{/* Add configmap using exclude key/value.  Expects name of policy in .name */}}
{{- define "kyverno-policies.configmap" -}}
{{- if (dig .name "parameters" nil .Values.policies) }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .name }}
  namespace: {{ .Release.Namespace }}
  labels: {{- include "kyverno-policies.labels" . | nindent 4 }}
data:
  {{- range $k, $v := (dig .name "parameters" nil .Values.policies) }}
    {{- $k | nindent 2 }}:
    {{- if (kindIs "slice" $v) }}
      {{- join " | " $v | quote | indent 1 }}
    {{- else }}
      {{- toYaml $v | indent 1 }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}