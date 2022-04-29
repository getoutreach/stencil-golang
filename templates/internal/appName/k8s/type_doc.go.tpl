{{ file.Skip "Virtual file to create kubernetes webhook/controller doc.go" }}

{{- define "internal/k8s/doc" -}}
// {{ stencil.ApplyTemplate "copyright" }} 

// Description: This file is docs for {{ .group }}/{{ .version }}.
// Managed: true

// Package {{ .version }} implements controllers or webhooks in this group.
package {{ .version }}
{{- end -}}

{{- $createController := (eq (stencil.ApplyTemplate "kubernetes.createController") "true") }}
{{- $createMutatingWebhook := (eq (stencil.ApplyTemplate "kubernetes.createMutatingWebhook") "true") }}

{{- range $g := stencil.Arg "kubernetes.groups" }}
  {{ if $createController }}
    {{ file.Create (printf "internal/k8s/controllers/%s/%s/doc.go" $g.package $g.version) 0600 now }}
    {{ file.SetContents (stencil.ApplyTemplate "internal/k8s/doc" $g) }}
  {{ end }}
  {{ if $createMutatingWebhook }}
    {{ file.Create (printf "internal/k8s/webhooks/%s/%s/doc.go" $g.package $g.version) 0600 now }}
    {{ file.SetContents (stencil.ApplyTemplate "internal/k8s/doc" $g) }}
  {{ end }}
{{- end }}
