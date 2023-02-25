# Contains asdf versions for a node.js gRPC client.
{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "node" -}}
nodejs {{ stencil.Arg "versions.grpcClients.nodejs" }}
