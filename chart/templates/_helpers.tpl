{{- define "imagePullSecret" }}
  {{- if .Values.registryCredentials -}}
    {{- $credType := typeOf .Values.registryCredentials -}}
          {{- /* If we have a list, embed that here directly. This allows for complex configuration from configmap, downward API, etc. */ -}}
    {{- if eq $credType "[]interface {}" -}}
    {{- include "multipleCreds" . | b64enc }}
    {{- else if eq $credType "map[string]interface {}" }}
      {{- /* If we have a map, treat those as key-value pairs. */ -}}
      {{- if and .Values.registryCredentials.username .Values.registryCredentials.password }}
      {{- with .Values.registryCredentials }}
      {{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
      {{- end }}
      {{- end }}
    {{- end -}}
  {{- end }}
{{- end }}

{{- define "multipleCreds" -}}
{
  "auths": {
    {{- range $i, $m := .Values.registryCredentials }}
    {{- /* Only create entry if resulting entry is valid */}}
    {{- if and $m.registry $m.username $m.password }}
    {{- if $i }},{{ end }}
    "{{ $m.registry }}": {
      "username": "{{ $m.username }}",
      "password": "{{ $m.password }}",
      "email": "{{ $m.email | default "" }}",
      "auth": "{{ printf "%s:%s" $m.username $m.password | b64enc }}"
    }
    {{- end }}
    {{- end }}
  }
}
{{- end }}

{{/*
Build the appropriate spec.ref.{} given git branch, commit values
*/}}
{{- define "validRef" -}}
{{- if .commit -}}
{{- if not .branch -}}
{{- fail "A valid branch is required when a commit is specified!" -}}
{{- end -}}
branch: {{ .branch | quote }}
commit: {{ .commit }}
{{- else if .semver -}}
semver: {{ .semver | quote }}
{{- else if .tag -}}
tag: {{ .tag }}
{{- else -}}
branch: {{ .branch | quote }}
{{- end -}}
{{- end -}}

{{/*
Check for git ref, given package values map
*/}}
{{- define "checkGitRef" -}}
{{- $git := (dig "git" dict .) -}}
{{- if not $git.repo -}}
false
{{- else -}}
{{- if $git.commit -}}
{{- if not $git.branch -}}
false
{{- end -}}
true
{{- else if $git.semver -}}
true
{{- else if $git.tag -}}
true
{{- else if $git.branch -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Build the appropriate git credentials secret for private git repositories
*/}}
{{- define "gitCreds" -}}
{{- if .Values.git.existingSecret -}}
secretRef:
  name: {{ .Values.git.existingSecret }}
{{- else if coalesce .Values.git.credentials.username .Values.git.credentials.password .Values.git.credentials.caFile .Values.git.credentials.privateKey .Values.git.credentials.publicKey .Values.git.credentials.knownHosts "" -}}
{{- /* Input validation happens in git-credentials.yaml template */ -}}
secretRef:
  name: {{ $.Release.Name }}-git-credentials
{{- end -}}
{{- end -}}

{{/*
Build common set of file extensions to include/exclude
*/}}
{{- define "gitIgnore" -}}
  ignore: |
    # exclude file extensions
    /**/*.md
    /**/*.txt
    /**/*.sh
    !/chart/tests/scripts/*.sh
{{- end -}}

{{/*
Common labels for all objects
*/}}
{{- define "commonLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ default .Chart.Version .Chart.AppVersion | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: "bigbang"
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "values-secret" -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .root.Release.Name }}-{{ .name }}-values
  namespace: {{ .root.Release.Namespace }}
type: generic
stringData:
  common: |
  defaults: {{- toYaml .defaults | nindent 4 }}
  overlays: |
    {{- toYaml .package.values | nindent 4 }}
{{- end -}}

{{/* 
bigbang.addValueIfSet can be used to nil check parameters before adding them to the values.
  Expects a list with the following params:
    * [0] - (string) <yaml_key_to_add>
    * [1] - (interface{}) <value_to_check>
  
  No output is generated if <value> is undefined, however, explicitly set empty values 
  (i.e. `username=""`) will be passed along. All string fields will be quoted.

  Example command: 
  - `{{ (list "name" .username) | include "bigbang.addValueIfSet" }}`
    * When `username: Aniken`
      -> `name: "Aniken"`
    * When `username: ""`
      -> `name: ""`
    * When username is not defined
      -> no output 
*/}}
{{- define "bigbang.addValueIfSet" -}}
  {{- $key := (index . 0) }}
  {{- $value := (index . 1) }}
  {{- /*If the value is explicitly set (even if it's empty)*/}}
  {{- if not (kindIs "invalid" $value) }}
    {{- /*Handle strings*/}}
    {{- if kindIs "string" $value }}
      {{- printf "\n%s" $key }}: {{ $value | quote }} 
    {{- /*Hanldle slices*/}}
    {{- else if kindIs "slice" $value }}
      {{- printf "\n%s" $key }}:    
        {{- range $value }}
          {{- if kindIs "string" . }}
            {{- printf "\n  - %s" (. | quote) }}
          {{- else }} 
            {{- printf "\n  - %v" . }}
          {{- end }}
        {{- end }}
    {{- /*Handle other types (no quotes)*/}}
    {{- else }}
      {{- printf "\n%s" $key }}: {{ $value }} 
    {{- end }}
  {{- end }}
{{- end -}}

{{/*
Annotation for Istio version
*/}}
{{- define "istioAnnotation" -}}
{{- if (eq (include "checkGitRef" .Values.istio) "true") -}}
{{- if .Values.istio.git.semver -}}
bigbang.dev/istioVersion: {{ .Values.istio.git.semver | trimSuffix (regexFind "-bb.*" .Values.istio.git.semver) }}
{{- else if .Values.istio.git.tag -}}
bigbang.dev/istioVersion: {{ .Values.istio.git.tag | trimSuffix (regexFind "-bb.*" .Values.istio.git.tag) }}
{{- else if .Values.istio.git.branch -}}
bigbang.dev/istioVersion: {{ .Values.istio.git.branch }}
{{- end -}}
{{- else -}}
bigbang.dev/istioVersion: {{ .Values.istio.oci.tag }}
{{- end -}}
{{- end -}}

{{- /* Helpers below this line are in support of the Big Bang extensibility feature */ -}}

{{- /* Converts the string in . to a legal Kubernetes resource name */ -}}
{{- define "resourceName" -}}
  {{- regexReplaceAll "\\W+" . "-" | trimPrefix "-" | trunc 63 | trimSuffix "-" | kebabcase -}}
{{- end -}}

{{- /* Returns a space separated string of unique namespaces where `<package>.enabled` and key held in `.constraint` are true */ -}}
{{- /* [Optional] Set `.constraint` to the key under <package> holding a boolean that must be true to be enabled */ -}}
{{- /* [Optional] Set `.default` to `true` to enable a `true` result when the `constraint` key is not found */ -}}
{{- /* To use: $ns := compact (splitList " " (include "uniqueNamespaces" (merge (dict "constraint" "some.boolean" "default" true) .))) */ -}}
{{- define "uniqueNamespaces" -}}
  {{- $namespaces := list -}}
  {{- range $pkg, $vals := .Values.packages -}}
    {{- if (dig "enabled" true $vals) -}}
      {{- $constraint := $vals -}}
      {{- range $key := split "." (default "" $.constraint) -}}
        {{- $constraint = (dig $key dict $constraint) -}}
      {{- end -}}
      {{- if (ternary $constraint (default false $.default) (kindIs "bool" $constraint)) -}}
        {{- $namespaces = append $namespaces (dig "namespace" "name" (include "resourceName" $pkg) $vals) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- join " " (uniq $namespaces) | trim -}}
{{- end -}}

{{- /* Prints istio version */ -}}
{{- define "istioVersion" -}}
{{ regexReplaceAll "-bb.+$" (coalesce .Values.istio.git.semver .Values.istio.git.tag .Values.istio.git.branch) "" }}
{{- end -}}
