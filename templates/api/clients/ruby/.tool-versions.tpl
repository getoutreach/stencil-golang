# Contains asdf versions for a ruby gRPC client.
{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "ruby" }}
ruby {{ stencil.Arg "versions.grpcClients.ruby" }}
## <<Stencil::Block(rubyToolVersions)>>
{{- if file.Block "rubyToolVersions" }}
{{ file.Block "rubyToolVersions" | stencil.Render "ruby" }}
{{- end }}
## <</Stencil::Block>>
