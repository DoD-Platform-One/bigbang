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
Build the appropriate git credentials secret for private git repositories
*/}}
{{- define "gitCreds" -}}
{{- if .Values.git.existingSecret -}}
secretRef:
  name: {{ .Values.git.existingSecret }}
{{- else if coalesce .Values.git.credentials.username .Values.git.credentials.password .Values.git.credentials.privateKey .Values.git.credentials.publicKey .Values.git.credentials.knownHosts "" -}}
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
{{- end -}}

{{/*
Common labels for all objects
*/}}
{{- define "commonLabels" -}}
app.kubernetes.io/instance: "{{ .Release.Name }}"
app.kubernetes.io/version: "{{ .Chart.Version }}"
app.kubernetes.io/part-of: "bigbang"
app.kubernetes.io/managed-by: "flux"
{{- end -}}