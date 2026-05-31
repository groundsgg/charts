{{/*
Expand the name of the chart.
*/}}
{{- define "service-notifications.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "service-notifications.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else if eq .Release.Name (include "service-notifications.name" .) }}
{{- include "service-notifications.name" . }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "service-notifications.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "service-notifications.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "service-notifications.labels" -}}
helm.sh/chart: {{ include "service-notifications.chart" . }}
{{ include "service-notifications.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "service-notifications.selectorLabels" -}}
app.kubernetes.io/name: {{ include "service-notifications.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Database Secret name.
*/}}
{{- define "service-notifications.databaseSecretName" -}}
{{- required "database.jdbcUrlSecretName is required" .Values.database.jdbcUrlSecretName }}
{{- end }}

{{/*
Service Secret name.
*/}}
{{- define "service-notifications.existingSecretName" -}}
{{- required "existingSecret.name is required" .Values.existingSecret.name }}
{{- end }}
