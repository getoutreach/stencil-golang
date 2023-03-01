{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "node" -}}
# Contains asdf versions for a node.js gRPC client.
nodejs {{ stencil.Arg "versions.grpcClients.nodejs" }}
