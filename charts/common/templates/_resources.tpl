{{/*
Resource limits and requests helper
*/}}
{{- define "common.resources" -}}
{{- if .Values.resources }}
{{ toYaml .Values.resources }}
{{- else }}
requests:
  cpu: "100m"
  memory: "128Mi"
limits:
  cpu: "500m"
  memory: "512Mi"
{{- end }}
{{- end }}

{{/*
Environment variables helper
*/}}
{{- define "common.env" -}}
{{- if .Values.env }}
{{- range $key, $value := .Values.env }}
{{- if kindIs "map" $value }}
- name: {{ $key }}
{{ toYaml $value | indent 2 }}
{{- else }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}
{{- if .Values.envFrom }}
{{- range .Values.envFrom }}
- envFrom:
{{ toYaml . | indent 2 }}
{{- end }}
{{- end }}
{{- end }}

