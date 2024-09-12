{{- define "values-bigbang" -}}
{{- /*
 * bigbang.values-bigbang: Produce a stripped version of the bigbang variables
 * in the root namespace suitable for inclusion in wrapper or package variables definitions
 */ -}}
{{ toYaml (pick $ "domain" "openshift") }}
{{- /* For every top level map, if it has the enable key, pass it through. */ -}}
{{- range $bbpkg, $bbvals := $ -}}
  {{- if kindIs "map" $bbvals -}}
    {{- if hasKey $bbvals "enabled" }}
{{ $bbpkg }}:
      {{- /* For network policies, we need all of its values. */ -}}
      {{- if eq $bbpkg "networkPolicies" -}}
        {{- toYaml $bbvals | nindent 2}}
      {{- else }}
  enabled: {{ $bbvals.enabled }}
      {{- end -}}
    {{- /* For addons, pass through the enable key. */ -}}
    {{- else if eq $bbpkg "addons" }}
{{ $bbpkg }}:
      {{- range $addpkg, $addvals := $bbvals -}}
        {{- if hasKey $addvals "enabled" }}
  {{ $addpkg }}:
    enabled: {{ $addvals.enabled }}
          {{- /* For authservice, the selector values are needed. */ -}}
          {{- if and (eq $addpkg "authservice") (or (dig "values" "selector" "key" false $addvals) (dig "values" "selector" "value" false $addvals)) }}
    values:
      selector:
              {{- if (dig "values" "selector" "key" false $addvals) }}
        key: {{ $addvals.values.selector.key }}
              {{- end -}}
              {{- if (dig "values" "selector" "value" false $addvals) }}
        value: {{ $addvals.values.selector.key }}
              {{- end -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end }}

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
Build the appropriate git credentials secret for BB wide git repositories
*/}}
{{- define "gitCredsGlobal" -}}
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
Build the appropriate git credentials secret for individual package and BB wide private git repositories
*/}}
{{- define "gitCredsExtended" -}}
{{- if .packageGitScope.existingSecret -}}
secretRef:
  name: {{ .packageGitScope.existingSecret }}
{{- else if and (.packageGitScope.credentials) (coalesce .packageGitScope.credentials.username .packageGitScope.credentials.password .packageGitScope.credentials.caFile .packageGitScope.credentials.privateKey .packageGitScope.credentials.publicKey .packageGitScope.credentials.knownHosts "") -}}
{{- /* Input validation happens in git-credentials.yaml template */ -}}
secretRef:
  name: {{ .releaseName }}-{{ .name }}-git-credentials
{{- else -}}
{{/* If no credentials are specified, use the global credentials in the rootScope */}}
{{- include "gitCredsGlobal" .rootScope }}
{{- end -}}
{{- end -}}

{{/*
Pointer to the appropriate git credentials template
*/}}
{{- define "gitCreds" -}}
{{- include "gitCredsGlobal" . }}
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
    !/chart/wait/*.sh
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
bigbang.dev/istioVersion: {{ .Values.istio.git.semver | trimSuffix (regexFind "-bb.*" .Values.istio.git.semver) }}{{ if .Values.istio.enterprise }}-enterprise{{ end }}
{{- else if .Values.istio.git.tag -}}
bigbang.dev/istioVersion: {{ .Values.istio.git.tag | trimSuffix (regexFind "-bb.*" .Values.istio.git.tag) }}{{ if .Values.istio.enterprise }}-enterprise{{ end }}
{{- else if .Values.istio.git.branch -}}
bigbang.dev/istioVersion: {{ .Values.istio.git.branch }}{{ if .Values.istio.enterprise }}-enterprise{{ end }}
{{- end -}}
{{- else -}}
bigbang.dev/istioVersion: {{ .Values.istio.helmRepo.tag }}{{ if .Values.istio.enterprise }}-enterprise{{ end }}
{{- end -}}
{{- end -}}

{{/*
App Label for Kiali trace correlation
To be used for Kiali-required labels on pods
This will:
  * enable proper linking of Jaeger traces in Kiali
  * enable full Kiali label tracking of pods
*/}}
{{- define "kialiAppLabel" -}}
app: {{ "{{ .Chart.Name }}" | quote }}
{{- end -}}

{{/*
Version label for Kiali trace correlation
To be used for Kiali-required labels on pods
This will:
  * enable proper linking of Jaeger traces in Kiali
  * enable full Kiali label tracking of pods
*/}}
{{- define "kialiVersionLabel" -}}
version: {{ "{{ .Chart.AppVersion }}" | quote }}
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

{{- /*
Returns the git credentails secret for the given scope and name
*/ -}}
{{- define "gitCredsSecret" -}}
{{- $name := .name }}
{{- $releaseName := .releaseName }}
{{- $releaseNamespace := .releaseNamespace }}
{{- with .targetScope -}}
{{- if and (eq .sourceType "git") .enabled }}
{{- if .git }}
{{- with .git -}}
{{- if not .existingSecret }}
{{- if .credentials }}
{{- if coalesce  .credentials.username .credentials.password .credentials.caFile .credentials.privateKey .credentials.publicKey .credentials.knownHosts -}}
{{- $http := coalesce .credentials.username .credentials.password .credentials.caFile "" }}
{{- $ssh := coalesce .credentials.privateKey .credentials.publicKey .credentials.knownHosts "" }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ $releaseName }}-{{ $name }}-git-credentials
  namespace: {{ $releaseNamespace }}
type: Opaque
data:
  {{- if $http }}
  {{- if .credentials.caFile }}
  caFile: {{ .credentials.caFile | b64enc }}
  {{- end }}
  {{- if and .credentials.username  (not .credentials.password ) }}
  {{- printf "%s - When using http git username, password must be specified" $name | fail }}
  {{- end }}
  {{- if and .credentials.password  (not .credentials.username ) }}
  {{- printf "%s - When using http git password, username must be specified" $name | fail }}
  {{- end }}
  {{- if and .credentials.username .credentials.password }}
  username: {{ .credentials.username | b64enc }}
  password: {{ .credentials.password | b64enc }}
  {{- end }}
  {{- else }}
  {{- if not (and (and .credentials.privateKey .credentials.publicKey) .credentials.knownHosts) }}
  {{- printf "%s - When using ssh git credentials, privateKey, publicKey, and knownHosts must all be specified" $name | fail }}
  {{- end }}
  identity: {{ .credentials.privateKey | b64enc }}
  identity.pub: {{ .credentials.publicKey | b64enc }}
  known_hosts: {{ .credentials.knownHosts | b64enc }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- /* Returns type of Helm Repository */ -}}
{{- define "getRepoType" -}}
  {{- $repoName := .repoName -}}
  {{- range .allRepos -}}
    {{- if eq .name $repoName -}}
      {{- print .type -}}
    {{- end -}}
  {{- end -}}
{{- end -}}


