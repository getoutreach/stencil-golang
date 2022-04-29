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
	k8slogging "github.com/getoutreach/services/pkg/k8s/logging"
	"github.com/getoutreach/services/pkg/k8s/controllers"
	"github.com/getoutreach/services/pkg/k8s/logging"
	"github.com/getoutreach/services/pkg/k8s/resources"
	"k8s.io/apimachinery/pkg/types"
	"sigs.k8s.io/controller-runtime/pkg/client"

	api{{ $g.version }} "github.com/getoutreach/{{ .Config.Name }}/api/k8s/{{if not (empty $g.package)}}{{ $g.package }}/{{end}}{{ $g.version }}"

	///Block(imports)
{{ file.Block "imports" }}
	///EndBlock(imports)
)

// {{ $ctrlStruct }} is a controller for {{ $r.kind }} resources.
type {{ $ctrlStruct }} struct {
	*controllers.Reconciler

	// Place extra fields here.
	///Block(controllerFields)
{{ file.Block "controllerFields" }}
	///EndBlock(controllerFields)
}

// New{{ $ctrlStruct }} creates a new instance of {{ $ctrlStruct }}
// to serve "{{ $r.kind }}" CRs.
func New{{ $ctrlStruct }} (cl client.Client) *{{ $ctrlStruct }} {
	ctrl := &{{ $ctrlStruct }} {}
	// use the controller as the Handler for Reconciler
	ctrl.Reconciler = controllers.NewReconciler(cl, "{{ $r.kind }}", "{{ $g.version }}", ctrl)
	return ctrl
}

// CreateResource returns new, empty {{ $r.kind }} object, it implements controllers.Handler.
func (r *{{ $ctrlStruct }}) CreateResource() resources.Resource {
	{{- if $isCustomResource }}
	// To ensure proper custom status handling, force the conversion
	// of the CR type to the resources.CustomResource interface before serving it to the Reconciler.
	// If the input does not fully satisfies the CustomResource interface, the Reconciler silently
	// ignores custom status presence.
	var cr resources.CustomResource = &api{{ $g.version }}.{{ $r.kind }}{}
	return cr
	{{- else }}
	return &api{{ $g.version }}.{{ $r.kind }}{}
	{{- end }}
}

// EndReconcile is invoked when Reconciler completes, it implements controllers.Handler.
// This method is for logging and metrics.
//nolint:unparam // Why: args ok to ignore
func (r *{{ $ctrlStruct }}) EndReconcile(
	ctx context.Context, req *logging.ReconcileRequest, rr controllers.ReconcileResult) {
	///Block(endReconcile)
{{ file.Block "endReconcile" }}
	///EndBlock(endReconcile)
}

// Reconcile is invoked when controller receives {{ $r.kind }} resource CR that hasn't been applied yet.
//nolint:unparam // Why: ctx or other params might be ignored.
func (r *{{ $ctrlStruct }}) Reconcile(
	ctx context.Context, inRes resources.Resource, req *logging.ReconcileRequest) controllers.ReconcileResult {
	// inRes was created by CreateResource, cast is totally safe
	in := inRes.(*api{{ $g.version }}.{{ $r.kind }})
	rr := controllers.ReconcileResult{}

	logger := log.With(req, &rr)

	///Block(controllerImpl)
	{{- if file.Block "controllerImpl" }}
{{ file.Block "controllerImpl" }}
	{{- else }}

	// Place controller implementation here, remove this once 'in' is used.
	_ = in

	{{- end }}
	///EndBlock(controllerImpl)

	logger.Info(ctx, "Reconcile completed.")
	return rr
}

erro

// NotFound callback is called when resource is detected as Not Found (e.g. deleted). Be careful
// handling deleted database resources, accidental delete of the CR can lead to a total data loss!
//nolint:unparam // Why: ctx or other params might be ignored.
func (r *{{ $ctrlStruct }}) NotFound(
	ctx context.Context, req *logging.ReconcileRequest) controllers.ReconcileResult {
	rr := controllers.ReconcileResult{}

	logger := log.With(req, &rr)

	///Block(notFoundImpl)
	{{- if file.Block "notFoundImpl" }}
{{ file.Block "notFoundImpl" }}
	{{- else }}

	// Be careful handling deleted database resources, accidental delete of the CR can lead to a total data loss!
	// It this operator deals with business data, is OK to leave this code empty and perform the cleanup manually.

	{{- end }}
	///EndBlock(notFoundImpl)

	logger.Info(ctx, "NotFound completed.")
	return rr
}

// Close cleans up the controller upon exit
func (r *{{ $ctrlStruct }}) Close(ctx context.Context) error {
	///Block(controllerClose)
{{ file.Block "controllerClose" }}
	///EndBlock(controllerClose)

	return nil
}

///Block(controllerAddons)
{{ file.Block "controllerAddons" }}
///EndBlock(controllerAddons)
{{- end -}}

{{- $root := . }}
{{- $createController := (eq (stencil.ApplyTemplate "kubernetes.createController") "true") }}
{{- range $g := stencil.Arg "kubernetes.groups" }}
{{- range $r := $g.Resources }}
  {{ if $createController }}
    {{ file.Create (printf "internal/k8s/controllers/%s/%s/%s.go" $g.package $g.version ($r.kind | lower)) 0600 now }}
    {{ file.SetContents (stencil.ApplyTemplate "internal/k8s/controller" (dict "Config" $root.Config "group" $g "resource" $r)) }}
  {{ end }}
{{- end }}
{{- end }}
