# Contains asdf versions for a node.js gRPC client.
{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "node" -}}
{{- /* TODO(jaredallard): We need a better solution for versions */}}
nodejs 14.17.6
