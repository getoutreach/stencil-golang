{{- if not (has "grpc" (stencil.Arg "serviceActivities")) }}
{{- file.Skip "Not a gRPC service" }}
{{- end }}
{{- $_ := file.SetPath (printf "api/%s/%s" .Config.Name (base file.Path)) }}
// {{ stencil.ApplyTemplate "copyright" }}

// Description: This file contains the package documentation for the gRPC
// client service interface package for {{ .Config.Name }}.

// Package {{ stencil.ApplyTemplate "goPackageSafeName" }} implements the client interface to the
// {{ .Config.Name }} gRPC service.
package {{ stencil.ApplyTemplate "goPackageSafeName" }} //nolint:revive,doculint // Why: We allow [-_].
