{{- define "fluentd.container" -}}
{{ if .Values.fluentd.enabled }}
- name: fluentd
  image: {{ .Values.fluentd.imageName }}
  command: ["sh", "-c", {{ include "fluentd.start.command" . | quote }}]
  ports:
    - containerPort: {{ .Values.fluentd.httpPort }}
      protocol: TCP
  volumeMounts:
    - name: fluentd-config
      mountPath: /fluentd/etc
      readOnly: true
{{- if .Values.fluentd.extraVolumes }}
  {{ toYaml .Values.fluentd.extraVolumes | nindent 4}}
{{- end }}
  env:
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    - name: HELM_RELEASE_NAME
      value: {{ include "common.names.fullname" . }}
{{ end }}
{{ end }}

{{- define "fluentd.config.volume" }}
{{ if .Values.fluentd.enabled }}
- name: fluentd-config
  configMap:
    name: {{ include "common.names.fullname" . }}-fluentd-config
{{ end }}
{{ end }}
