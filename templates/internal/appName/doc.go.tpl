{{- $_ := file.SetPath (printf "internal/%s/%s" .Config.Name (base file.Path)) }}
// {{ stencil.ApplyTemplate "copyright" }} 

// Description: This file contains the package documentation for {{ .Config.Name }}.

// Package {{ stencil.ApplyTemplate "goPackageSafeName" }} contains the base activities
// that make up the service.
package {{ stencil.ApplyTemplate "goPackageSafeName" }} //nolint:revive // Why: We allow [-_].
