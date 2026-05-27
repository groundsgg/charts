{{/*
Expand the name of the chart.
*/}}
{{- define "novu.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "novu.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "novu.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "novu.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "novu.labels" -}}
helm.sh/chart: {{ include "novu.chart" . }}
{{ include "novu.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "novu.selectorLabels" -}}
app.kubernetes.io/name: {{ include "novu.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Component name.
*/}}
{{- define "novu.componentName" -}}
{{- printf "%s-%s" (include "novu.fullname" .root) .component | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Component selector labels.
*/}}
{{- define "novu.componentSelectorLabels" -}}
{{ include "novu.selectorLabels" .root }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Component object labels.
*/}}
{{- define "novu.componentLabels" -}}
{{ include "novu.labels" .root }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Secret name used for Novu sensitive configuration.
*/}}
{{- define "novu.secretName" -}}
{{- if .Values.novu.existingSecret.name }}
{{- .Values.novu.existingSecret.name }}
{{- else }}
{{- printf "%s-secret" (include "novu.fullname" .) }}
{{- end }}
{{- end }}

{{/*
MongoDB connection string.
*/}}
{{- define "novu.mongodbUri" -}}
{{- if .Values.novu.mongodb.externalUri }}
{{- .Values.novu.mongodb.externalUri }}
{{- else if not .Values.mongodb.enabled }}
{{- fail "novu.mongodb.externalUri is required when mongodb.enabled is false" }}
{{- else if .Values.mongodb.auth.enabled }}
{{- fail "novu.mongodb.externalUri is required when mongodb.auth.enabled is true" }}
{{- else }}
{{- printf "mongodb://%s-mongodb:27017/novu" .Release.Name }}
{{- end }}
{{- end }}

{{/*
Redis host.
*/}}
{{- define "novu.redisHost" -}}
{{- if .Values.novu.redis.externalHost }}
{{- .Values.novu.redis.externalHost }}
{{- else }}
{{- printf "%s-redis-master" .Release.Name }}
{{- end }}
{{- end }}
