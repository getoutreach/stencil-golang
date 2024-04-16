# {{ stencil.ApplyTemplate "copyright" }}
{{- $_ := file.SetPath (printf "api/clients/ruby/lib/%s_client.rb" .Config.Name) }}
{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "ruby" }}

require "{{ .Config.Name }}_client/client"
require "{{ .Config.Name }}_client/version"
{{- if stencil.Arg "service" }}
require "{{ .Config.Name }}_client/{{ .Config.Name }}_pb"
require "{{ .Config.Name }}_client/{{ .Config.Name }}_services_pb"
{{- end }}

## <<Stencil::Block(extraClientCode)>>
{{ file.Block "extraClientCode" }}
## <</Stencil::Block>>
