{{ file.Skip "Virtual file to create kubernetes controller" }}

{{- define "internal/k8s/controller" -}}
// {{ stencil.ApplyTemplate "copyright" }}
{{- $g := .group }}
{{- $r := .resource }}
{{- $isCustomResource := contains "." $g.group }}
{{- $ctrlStruct := printf "%sReconciler" $r.kind }}

// Description: This file defines a kubernetes controller for {{ $g.version }}/{{ $r.kind }}.
// Managed: true

package {{ $g.version }}

import (
	"context"

	"github.com/getoutreach/gobox/pkg/log"
	k8slogging "github.com/getoutreach/services/pkg/k8slib/logging"
	"github.com/getoutreach/services/pkg/k8slib/controllers"
	"github.com/getoutreach/services/pkg/k8slib/logging"
	"github.com/getoutreach/services/pkg/k8slib/resources"
	"k8s.io/apimachinery/pkg/types"
	"sigs.k8s.io/controller-runtime/pkg/client"
    ctrl "sigs.k8s.io/controller-runtime"

	api{{ $g.version }} "github.com/getoutreach/{{ .Config.Name }}/api/k8s/{{if not (empty $g.package)}}{{ $g.package }}/{{end}}{{ $g.version }}"

	// <<Stencil::Block(imports)>>
{{ file.Block "imports" }}
	// <</Stencil::Block>>
)

// {{ $ctrlStruct }} is a controller for {{ $r.kind }} resources.
type {{ $ctrlStruct }} struct {
	*controllers.Reconciler

	// Place extra fields here.
	// <<Stencil::Block(controllerFields)>>
{{ file.Block "controllerFields" }}
	// <</Stencil::Block>>
}

// New{{ $ctrlStruct }} creates a new instance of {{ $ctrlStruct }}
// to serve "{{ $r.kind }}" CRs.
func New{{ $ctrlStruct }} (cl client.Client, options controller.Options) *{{ $ctrlStruct }} {
	r := &{{ $ctrlStruct }} {}
	// use the controller as the Handler for Reconciler
	r.Reconciler = controllers.NewReconciler(cl, 
      "{{ $r.kind }}",
      "{{ $g.version }}", 
      r,
      options)
	return r
}

// CreateResource returns new, empty {{ $r.kind }} object, it implements controllers.Handler.
func (r *{{ $ctrlStruct }}) CreateResource() resources.Resource {
	{{- if $isCustomResource }}
    // To ensure proper custom status handling, force the conversion of the CR type
    // to the resources.CustomResource interface before serving it to the Reconciler.
    // If the input does not fully satisfy the CustomResource interface, the
    // Reconciler silently ignores custom status presence.
	var cr resources.CustomResource = &api{{ $g.version }}.{{ $r.kind }}{}
	return cr
	{{- else }}
	return &api{{ $g.version }}.{{ $r.kind }}{}
	{{- end }}
}


// Reconcile is invoked when controller receives {{ $r.kind }} resource CR that hasn't been applied yet.
//nolint:unparam // Why: ctx or other params might be ignored.
func (r *{{ $ctrlStruct }}) Reconcile(
	ctx context.Context, inRes resources.Resource, req *logging.ReconcileRequest) (ctrl.Result, error) {
	// inRes was created by CreateResource, cast is totally safe
	in := inRes.(*api{{ $g.version }}.{{ $r.kind }})

	logger := log.With(req)

	// <<Stencil::Block(controllerImpl)>>
	{{- if file.Block "controllerImpl" }}
{{ file.Block "controllerImpl" }}
	{{- else }}

	// Place controller implementation here, remove this once 'in' is used.
	_ = in

	{{- end }}
	// <</Stencil::Block>>

	logger.Info(ctx, "reconcile completed.")
	return ctrl.Result{}, nil
}

// Close cleans up the controller upon exit
func (r *{{ $ctrlStruct }}) Close(ctx context.Context) error {
	// <<Stencil::Block(controllerClose)>>
{{ file.Block "controllerClose" }}
	// <</Stencil::Block>>

	return nil
}

// <<Stencil::Block(controllerAddons)>>
{{ file.Block "controllerAddons" }}
// <</Stencil::Block>>
{{- end -}}

{{- $root := . }}
{{- $createController := (eq (stencil.ApplyTemplate "kubernetes.createController") "true") }}
{{- range $g := stencil.Arg "kubernetes.groups" }}
{{- range $r := $g.resources }}
  {{ if $createController }}
    {{ file.Create (printf "internal/controllers/%s/%s/%s.go" $g.package $g.version ($r.kind | lower)) 0600 now }}
    {{ file.SetContents (stencil.ApplyTemplate "internal/k8s/controller" (dict "Config" $root.Config "group" $g "resource" $r)) }}
  {{ end }}
{{- end }}
{{- end }}
