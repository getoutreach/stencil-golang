# {{ stencil.ApplyTemplate "copyright" }} 
{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "ruby" }}
{{- $_ := file.SetPath (printf "api/clients/ruby/lib/%s_client/%s" .Config.Name (base file.Path)) }}
{{- $_ := file.Static }}
module {{ title .Config.Name }}Client
  VERSION = "1.0.0"
end
