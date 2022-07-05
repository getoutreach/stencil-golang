{{- if not (has "grpc" (stencil.Arg "serviceActivities")) }}
{{- file.Skip "Not a gRPC service" }}
{{- end }}
{{- $_ := file.SetPath (printf "api/%s.go" .Config.Name) }}
{{- $_ := file.Static }}
// {{ stencil.ApplyTemplate "copyright" }}

// Description: This file defines the gRPC server service interface for
// {{ .Config.Name }}.

package api

import (
	"context"
)

// Service is the {{ regexReplaceAllLiteral "\\W+" .Config.Name " " | title | replace " " "" }} server interface
//
// This interface is implemented by the server and the rpc client
type Service interface {
	// Close all connections and release resources.
	Close(ctx context.Context) error
	Ping(ctx context.Context, message string) (string, error)
	Pong(ctx context.Context, message string) (string, error)
{{- range stencil.GetModuleHook "api.Service" }}
{{- . | indent 2}}
{{- end }}
}
