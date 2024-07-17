{{- $_ := file.Skip "Test file" }}
{{- $serviceActivities := (stencil.Arg "serviceActivities") }}
{{- $grpcClients := (stencil.Arg "grpcClients") }}
{{- if and (or (not (stencil.Arg "service")) (has "grpc" $serviceActivities)) (has "ruby" $grpcClients) }}
  {{- range (stencil.ApplyTemplate "toolVersions" | fromYaml) }}
    {{- if eq .name "ruby" }}{{/* Only emit ruby to reduce diffs when tool versions are updated */}}
- name: {{ .name }}
  version: {{ .version }}
    {{- end }}
  {{- end }}
{{- end }}
