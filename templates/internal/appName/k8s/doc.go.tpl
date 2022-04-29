// {{ stencil.ApplyTemplate "copyright" }} 
{{- $_ := file.SetPath (printf "internal/k8s/%s" (base file.Path)) }}
{{- $_ := stencil.ApplyTemplate "kubernetes.skipIfNot" }}

// Description: This file contains the package documentation for the k8s package.
// Managed: true

// Package k8s contains the needed functionality for the Kubernetes controller/webhook
// integration for the types in api/k8s
package k8s
