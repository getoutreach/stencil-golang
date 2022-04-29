{{ file.Skip "Virtual file to create kubernetes webhook/controller doc.go" }}

{{- define "internal/k8s/doc" }}
// {{ stencil.ApplyTemplate "copyright" }} 

// Description: This file is docs for {{ .Group }}/{{ .Version }}.
// Managed: true

// Package {{ .Version }} implements controllers or webhooks in this group.
package {{ .Version }}
{{- end }}

{{- $createController := (eq (stencil.ApplyTemplate "kubernetes.createController") "true") }}
{{- $createMutatingWebhook := (eq (stencil.ApplyTemplate "kubernetes.createMutatingWebhook") "true") }}

{{- range $g := stencil.Arg "kubernetes.groups" }}
  {{ if $createController }}
    {{ file.Create (printf "internal/controllers/%s/%s/doc.go" $g.Package $g.Version) 0600 now }}
    {{ file.SetContents (stencil.ApplyTemplate "internal/k8s/doc" $g) }}
  {{ end }}
  {{ if $createMutatingWebhook }}
    {{ file.Create (printf "internal/webhooks/%s/%s/doc.go" $g.Package $g.Version) 0600 now }}
    {{ file.SetContents (stencil.ApplyTemplate "internal/k8s/doc" $g) }}
  {{ end }}
{{- end }}
