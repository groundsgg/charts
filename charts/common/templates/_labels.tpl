{{/*
Common labels
*/}}
{{- define "common.labels" -}}
helm.sh/chart: {{ include "common.chart" . }}
{{ include "common.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "common.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Service labels
*/}}
{{- define "common.serviceLabels" -}}
{{ include "common.labels" . }}
{{- end }}

{{/*
Deployment labels
*/}}
{{- define "common.deploymentLabels" -}}
{{ include "common.labels" . }}
{{- end }}

{{/*
Pod labels
*/}}
{{- define "common.podLabels" -}}
{{ include "common.selectorLabels" . }}
{{- with .Values }}
{{- if .podLabels }}
{{ toYaml .podLabels }}
{{- end }}
{{- end }}
{{- end }}

