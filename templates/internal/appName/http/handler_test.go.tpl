{{- if not (has "http" (stencil.Arg "serviceActivities")) }}
{{ file.Skip "Not a HTTP service" }}
{{- end }}
{{- $_ := file.SetPath (printf "internal/%s/%s" .Config.Name (base file.Path)) }}
{{ file.Delete }}
