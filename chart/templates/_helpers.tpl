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
{{- if (eq .Values.istio.sourceType "git") -}}
{{- if .Values.istio.git.semver -}}
bigbang.dev/istioVersion: {{ .Values.istio.git.semver | trimSuffix (regexFind "-bb.*" .Values.istio.git.semver) }}
{{- else if .Values.istio.git.tag -}}
bigbang.dev/istioVersion: {{ .Values.istio.git.tag | trimSuffix (regexFind "-bb.*" .Values.istio.git.tag) }}
{{- else if .Values.istio.git.branch -}}
bigbang.dev/istioVersion: {{ .Values.istio.git.branch }}
{{- end -}}
{{- else -}}
bigbang.dev/istioVersion: {{ .Values.istio.helmRepo.tag }}
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
  {{- regexReplaceAll "-bb.+$" (coalesce .Values.istio.git.semver .Values.istio.git.tag .Values.istio.git.branch) "" -}}
{{- end -}}

{{- /* Returns an SSO host */ -}}
{{- define "sso.host" -}}
  {{- coalesce .Values.sso.oidc.host (regexReplaceAll ".*//([^/]*)/?.*" .Values.sso.url "${1}") -}}
{{- end -}}

{{- /* Returns an SSO realm */ -}}
{{- define "sso.realm" -}}
  {{- coalesce .Values.sso.oidc.realm (regexReplaceAll ".*/realms/([^/]*)" .Values.sso.url "${1}") (regexReplaceAll "\\W+" .Values.sso.name "") -}}
{{- end -}}

{{- /* Returns the SSO base URL */ -}}
{{- define "sso.url" -}}
  {{- if and .Values.sso.oidc.host .Values.sso.oidc.realm -}}
    {{- printf "https://%s/auth/realms/%s" .Values.sso.oidc.host .Values.sso.oidc.realm -}}
  {{- else -}}
    {{- tpl (default "" .Values.sso.url) . -}}
  {{- end -}}
{{- end -}}

{{- /* Returns the SSO auth url (OIDC) */ -}}
{{- define "sso.oidc.auth" -}}
  {{- if .Values.sso.auth_url -}}
    {{- tpl (default "" .Values.sso.auth_url) . -}}
  {{- else if and .Values.sso.oidc.host .Values.sso.oidc.realm -}}
    {{- printf "%s/protocol/openid-connect/auth" (include "sso.url" .) -}}
  {{- else -}}
    {{- tpl (dig "oidc" "authorization" (printf "%s/protocol/openid-connect/auth" (include "sso.url" .)) .Values.sso) . -}}
  {{- end -}}
{{- end -}}

{{- /* Returns the SSO token url (OIDC) */ -}}
{{- define "sso.oidc.token" -}}
  {{- if .Values.sso.token_url -}}
    {{- tpl (default "" .Values.sso.token_url) . -}}
  {{- else if and .Values.sso.oidc.host .Values.sso.oidc.realm -}}
    {{- printf "%s/protocol/openid-connect/token" (include "sso.url" .) -}}
  {{- else -}}
    {{- tpl (dig "oidc" "token" (printf "%s/protocol/openid-connect/token" (include "sso.url" .)) .Values.sso) . -}}
  {{- end -}}
{{- end -}}

{{- /* Returns the SSO userinfo url (OIDC) */ -}}
{{- define "sso.oidc.userinfo" -}}
  {{- if and .Values.sso.oidc.host .Values.sso.oidc.realm -}}
    {{- printf "%s/protocol/openid-connect/userinfo" (include "sso.url" .) -}}
  {{- else -}}
    {{- tpl (dig "oidc" "userinfo" (printf "%s/protocol/openid-connect/userinfo" (include "sso.url" .)) .Values.sso) . -}}
  {{- end -}}
{{- end -}}

{{- /* Returns the SSO jwks url (OIDC) */ -}}
{{- define "sso.oidc.jwksuri" -}}
  {{- if .Values.sso.jwks_uri -}}
    {{- tpl (default "" .Values.sso.jwks_uri) . -}}
  {{- else if and .Values.sso.oidc.host .Values.sso.oidc.realm -}}
    {{- printf "%s/protocol/openid-connect/certs" (include "sso.url" .) -}}
  {{- else -}}
    {{- tpl (dig "oidc" "jwksUri" (printf "%s/protocol/openid-connect/certs" (include "sso.url" .)) .Values.sso) . -}}
  {{- end -}}
{{- end -}}

{{- /* Returns the SSO end session url (OIDC) */ -}}
{{- define "sso.oidc.endsession" -}}
  {{- if and .Values.sso.oidc.host .Values.sso.oidc.realm -}}
    {{- printf "%s/protocol/openid-connect/logout" (include "sso.url" .) -}}
  {{- else -}}
    {{- tpl (dig "oidc" "endSession" (printf "%s/protocol/openid-connect/logout" (include "sso.url" .)) .Values.sso) . -}}
  {{- end -}}
{{- end -}}

{{- /* Returns the single sign on service (SAML) */ -}}
{{- define "sso.saml.service" -}}
  {{- if and .Values.sso.oidc.host .Values.sso.oidc.realm -}}
    {{- printf "%s/protocol/saml" (include "sso.url" .) -}}
  {{- else -}}
    {{- tpl (dig "saml" "service" (printf "%s/protocol/saml" (include "sso.url" .)) .Values.sso) . -}}
  {{- end -}}
{{- end -}}

{{- /* Returns the single sign on entity descriptor (SAML) */ -}}
{{- define "sso.saml.descriptor" -}}
  {{- if and .Values.sso.oidc.host .Values.sso.oidc.realm -}}
    {{- printf "%s/descriptor" (include "sso.saml.service" .) -}}
  {{- else -}}
    {{- tpl (dig "saml" "entityDescriptor" (printf "%s/descriptor" (include "sso.saml.service" .)) .Values.sso) . -}}
  {{- end -}}
{{- end -}}

{{- /* Returns the signing cert (no headers) from the SAML metadata */ -}}
{{- define "sso.saml.cert" -}}
  {{- $cert := dig "saml" "metadata" "" .Values.sso -}}
  {{- if $cert -}}
    {{- $cert := regexFind "<md:IDPSSODescriptor[\\s>][\\s\\S]*?</md:IDPSSODescriptor[\\s>]" $cert -}}
    {{- $cert = regexFind "<md:KeyDescriptor[\\s>][^>]*?use=\"signing\"[\\s\\S]*?</md:KeyDescriptor[\\s>]" $cert -}}
    {{- $cert = regexFind "<ds:KeyInfo[\\s>][\\s\\S]*?</ds:KeyInfo[\\s>]" $cert -}}
    {{- $cert = regexFind "<ds:X509Data[\\s>][\\s\\S]*?</ds:X509Data[\\s>]" $cert -}}
    {{- $cert = regexFind "<ds:X509Certificate[\\s>][\\s\\S]*?</ds:X509Certificate[\\s>]" $cert -}}
    {{- $cert = regexReplaceAll "<ds:X509Certificate[^>]*?>\\s*([\\s\\S]*?)</ds:X509Certificate[\\s>]" $cert "${1}" -}}
    {{- $cert = regexReplaceAll "\\s*" $cert "" -}}
    {{- required "X.509 signing certificate could not be found in sso.saml.metadata!" $cert -}}
  {{- end -}}
{{- end -}}

{{- /* Returns the signing cert with headers from the SAML metadata */ -}}
{{- define "sso.saml.cert.withheaders" -}}
  {{- $cert := include "sso.saml.cert" . -}}
  {{- if $cert -}}
    {{- printf "-----BEGIN CERTIFICATE-----\n%s\n-----END CERTIFICATE-----" $cert -}}
  {{- end -}}
{{- end -}}