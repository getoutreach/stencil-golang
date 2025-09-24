{{ file.Skip "Virtual file to create kubernetes webhook" }}

{{- define "internal/k8s/webhook" -}}
// {{ stencil.ApplyTemplate "copyright" }}
{{- $g := .group }}
{{- $r := .resource }}
{{- $webhookStruct := printf "%sWebhook" $r.kind }}

// Description: This file defines a kubernetes webhook for {{ $g.version }}/{{ $r.kind }}.
// Managed: true

package {{ $g.version }}

import (
	"context"

	ctrl "sigs.k8s.io/controller-runtime"

	"github.com/getoutreach/gobox/pkg/events"
	"github.com/getoutreach/gobox/pkg/log"
	api{{ $g.version }} "github.com/getoutreach/{{ .Config.Name }}/api/k8s/{{if not (empty $g.package)}}{{ $g.package }}/{{end}}{{ $g.version }}"

	// <<Stencil::Block(imports)>>
{{ file.Block "imports" }}
	// <</Stencil::Block>>
)

// {{ $webhookStruct }} registers the webhook for {{ $r.kind }}.
// All webhook related functionality should be implemented on the
// {{ $r.kind }} type itself.
type {{ $webhookStruct }} struct {
	// Place extra fields here.
	// <<Stencil::Block(webhookFields)>>
{{ file.Block "webhookFields" }}
	// <</Stencil::Block>>
}

// MarshalLog implements log.Marshaler for use in logging/tracing/metrics
func (r *{{ $webhookStruct }}) MarshalLog(addField func(k string, v interface{})) {
	addField("resource.kind", "{{ $r.kind }}")
	addField("resource.version", "{{ $g.version }}")
	addField("controller.type", "webhook")
}

// Kind returns the k8s kind served by this webhook
func (r *{{ $webhookStruct }}) Kind() string {
	return "{{ $r.kind }}"
}

// Version returns the version of this webhook
func (r *{{ $webhookStruct }}) Version() string {
	// we always lowercase the version when used with K8s
	return "{{ $g.version }}"
}

// Setup registers the {{ $webhookStruct }} as a webhook with the manager.
func (r *{{ $webhookStruct }}) Setup(mgr ctrl.Manager) error {
	// all relevant validation or other webhook related methods must be defined on the {{ $r.kind }} itself
	err := ctrl.NewWebhookManagedBy(mgr).
		{{- if eq $r.addConfig "false" }}
		For(&api{{ $g.version }}.{{ $r.kind }}{}).
		{{- else }}
		For(&api{{ $g.version }}.New{{ $r.kind }}(r.Config)).
		{{- end }}
		Complete()
	if err != nil {
		log.Error(context.Background(), "failed to register webhook handler", r, events.Err(err))
	}
	return err
}

// Close cleans up the resource upon exit.
func (r *{{ $webhookStruct }}) Close(ctx context.Context) error {
	// <<Stencil::Block(webhookClose)>>
{{ file.Block "webhookClose" }}
	// <</Stencil::Block>>

	return nil
}

// <<Stencil::Block(webhookAddons)>>
{{ file.Block "webhookAddons"}}
// <</Stencil::Block>>
{{- end -}}

{{- $root := . }}
{{- $createMutatingWebhook := (eq (stencil.ApplyTemplate "kubernetes.createMutatingWebhook") "true") }}
{{- range $g := stencil.Arg "kubernetes.groups" }}
{{- range $r := $g.resources }}
  {{ if $createMutatingWebhook }}
    {{ file.Create (printf "internal/webhooks/%s/%s/%s.go" $g.package $g.version ($r.kind | lower)) 0600 now }}
    {{ file.SetContents (stencil.ApplyTemplate "internal/k8s/webhook" (dict "Config" $root.Config "group" $g "resource" $r)) }}
  {{ end }}
{{- end }}
{{- end }}
