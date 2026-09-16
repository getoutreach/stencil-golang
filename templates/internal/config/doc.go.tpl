{{- $hasConfig := false }}
{{- range $g := stencil.Arg "kubernetes.groups" }}
{{- range $r := $g.resources }}
{{- if $r.addConfig }}
{{- $hasConfig = true }}
{{- end }}
{{- end }}
{{- end }}
{{- if not $hasConfig -}}
{{- $_ := file.Skip "No Kubernetes resource has addConfig set" -}}
{{- else -}}
// {{ stencil.ApplyTemplate "copyright" }}

// Description: This file enables deepcopy generation for the internal/config package,
// which is required for Kubernetes types generated with addConfig set.
// Managed: true

// Package config's own documentation lives in config.go; this file only
// carries the deepcopy generation marker below.
//
// +kubebuilder:object:generate=true
package config
{{- end -}}
