{{- $_ := file.Skip "Test file" }}
{{- $serviceActivities := (stencil.Arg "serviceActivities") }}
{{- $grpcClients := (stencil.Arg "grpcClients") }}
{{- if and (or (not (stencil.Arg "service")) (has "grpc" $serviceActivities)) (has "ruby" $grpcClients) }}
{{ stencil.ApplyTemplate "toolVersions" }}
{{- end }}
