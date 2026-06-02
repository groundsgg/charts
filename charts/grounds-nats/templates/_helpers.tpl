{{- define "grounds-nats.fullname" -}}{{ printf "%s-%s" .Release.Name "nats" | trunc 63 | trimSuffix "-" }}{{- end -}}
