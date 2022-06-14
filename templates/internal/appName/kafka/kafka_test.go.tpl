{{- if not (has "kafka" (stencil.Arg "serviceActivities")) }}
{{ file.Skip "Not a Kafka service" }}
{{- end }}
{{ file.Delete }}
