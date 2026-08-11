{{- if not (has "grpc" (stencil.Arg "serviceActivities")) }}
{{- file.Skip "Not a gRPC service" }}
{{- end }}
// {{ stencil.ApplyTemplate "copyright" }}

// Description: This file contains generic RPC helpers

package api

{{- if not (stencil.Arg "disableGrpcGeneration") }}
// The following line(s) generate code using protobuf (e.g. {{ .Config.Name }}.pb.go)
//
//go:generate ../scripts/shell-wrapper.sh protoc.sh
{{- end }}
