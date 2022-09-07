{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
{{- $_ := file.SetPath (printf "internal/%s/%s" .Config.Name (base file.Path)) }}
{{- $_ := file.Delete }}
