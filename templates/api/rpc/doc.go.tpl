// {{ stencil.ApplyTemplate "copyright" }} 

// Description: This file contains the package documentation for the gRPC
// client service interface package for {{ .Config.Name }}.

// Package {{ stencil.ApplyTemplate "goPackageSafeName" }} implements the client interface to the
// {{ .Config.Name }} gRPC service.
package {{ stencil.ApplyTemplate "goPackageSafeName" }} //nolint:revive // Why: We allow [-_].
