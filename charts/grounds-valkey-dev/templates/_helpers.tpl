{{- define "grounds-valkey-dev.fullname" -}}{{ .Release.Name | trunc 63 | trimSuffix "-" }}{{- end -}}
