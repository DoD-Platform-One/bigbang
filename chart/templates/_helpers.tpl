{{- define "imagePullSecret" }}
  {{- if .Values.registryCredentials -}}
    {{- $credType := typeOf .Values.registryCredentials -}}
          {{- /* If we have a list, embed that here directly. This allows for complex configuration from configmap, downward API, etc. */ -}}
    {{- if eq $credType "[]interface {}" -}}
    {{- include "multipleCreds" . | b64enc }}
    {{- else if eq $credType "map[string]interface {}" }}
      {{- /* If we have a map, treat those as key-value pairs. */ -}}
      {{- with .Values.registryCredentials }}
      {{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
      {{- end }}
    {{- end -}}
  {{- end }}
{{- end }}

{{- define "multipleCreds" -}}
{
  "auths": {
    {{- $length := len .Values.registryCredentials }}
    {{- range $index, $entry := .Values.registryCredentials }}
    "{{- $entry.registry }}": {
      "username{{ $index }}":"{{- $entry.username }}",
      "password":"{{- $entry.password }}",
      "email":"{{- $entry.email }}",
      "auth":"{{- (printf "%s:%s" $entry.username $entry.password | b64enc) }}"
    }{{- if ne $length (add $index 1) }},{{- end }}
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
{{- if .existingSecret -}}
secretRef:
  name: {{ .existingSecret }}
{{- else if coalesce .credentials.username .credentials.password .credentials.privateKey .credentials.publicKey .credentials.knownHosts "" -}}
{{- /* Input validation happens in git-credentials.yaml template */ -}}
secretRef:
  name: git-credentials
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