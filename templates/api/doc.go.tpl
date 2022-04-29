{{- if not (has "grpc" (stencil.Arg "serviceActivities")) }}
{{- file.Skip "Not a gRPC service" }}
{{- end }}
// {{ stencil.ApplyTemplate "copyright" }} 

// Description: This file serves as package documentation for the api
// package.

// Package api defines the interface to the {{ .Config.Name }} service.
//
// Please see api/{{ .Config.Name }} for the client implementation.
//
// Please edit this to accurately reflect the service interface.
//
// Note all arguments must accept a context.Context as the first
// argument.
package api
