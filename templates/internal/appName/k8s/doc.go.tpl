{{- $_ := file.SetPath (printf "internal/%s/%s" .Config.Name (base file.Path)) }}
{{- $_ := stencil.ApplyTemplate "kubernetes.skipIfNot" }}
// {{ stencil.ApplyTemplate "copyright" }} 

// Description: This file contains the package documentation for the k8s package.
// Managed: true

// Package k8s contains the needed functionality for the Kubernetes controller/webhook
// integration for the types in api/k8s
package k8s
