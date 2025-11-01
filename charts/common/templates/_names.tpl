{{/*
Expand the name of the chart.
*/}}
{{- define "common.name" -}}
{{- $nameOverride := "" }}
{{- if .Values.global.nameOverride }}
{{- $nameOverride = .Values.global.nameOverride }}
{{- end }}
{{- default .Chart.Name $nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "common.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $nameOverride := "" }}
{{- if .Values.global.nameOverride }}
{{- $nameOverride = .Values.global.nameOverride }}
{{- end }}
{{- $name := default .Chart.Name $nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "common.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}
