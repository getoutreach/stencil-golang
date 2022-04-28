# Contains asdf versions for a ruby gRPC client.
{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "ruby" -}}
ruby 2.6.6
###Block(rubyToolVersions)
{{- if file.Block "rubyToolVersions" }}
{{ file.Block "rubyToolVersions" | stencil.Render "ruby" }}
{{- end }}
###EndBlock(rubyToolVersions)
