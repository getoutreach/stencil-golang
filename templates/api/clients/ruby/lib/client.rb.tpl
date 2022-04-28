# {{ stencil.ApplyTemplate "copyright" }} 
{{- if not (has "grpc" (stencil.Arg "type")) }}
{{ file.Skip "Not a gRPC service" }}
{{- end }}
{{- $_ := file.SetPath (printf "api/clients/ruby/lib/%s_client.rb" .Config.Name) }}

require "{{ .Config.Name }}_client/client"
require "{{ .Config.Name }}_client/version"
require "{{ .Config.Name }}_client/{{ .Config.Name }}_pb"
require "{{ .Config.Name }}_client/{{ .Config.Name }}_services_pb"
