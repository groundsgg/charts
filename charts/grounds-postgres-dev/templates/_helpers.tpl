{{- define "grounds-postgres-dev.fullname" -}}{{ .Release.Name | trunc 63 | trimSuffix "-" }}{{- end -}}
