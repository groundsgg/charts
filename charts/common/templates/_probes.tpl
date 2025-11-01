{{/*
Liveness probe helper
*/}}
{{- define "common.livenessProbe" -}}
httpGet:
  path: {{ .Values.healthCheck.path | default "/health" }}
  port: {{ .Values.service.port | default 3000 }}
{{- if .Values.healthCheck.livenessProbe }}
{{ toYaml .Values.healthCheck.livenessProbe }}
{{- else }}
initialDelaySeconds: 30
periodSeconds: 10
timeoutSeconds: 5
failureThreshold: 3
{{- end }}
{{- end }}

{{/*
Readiness probe helper
*/}}
{{- define "common.readinessProbe" -}}
httpGet:
  path: {{ .Values.healthCheck.path | default "/health" }}
  port: {{ .Values.service.port | default 3000 }}
{{- if .Values.healthCheck.readinessProbe }}
{{ toYaml .Values.healthCheck.readinessProbe }}
{{- else }}
initialDelaySeconds: 10
periodSeconds: 5
timeoutSeconds: 3
failureThreshold: 3
{{- end }}
{{- end }}

