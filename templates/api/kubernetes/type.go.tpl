{{ file.Skip "Virtual file to generate kubernetes type files" }}

{{- define "api/kubernetes/type" -}}
// {{ stencil.ApplyTemplate "copyright" }} 
{{- $g := .group }}
{{- $r := .resource }}
{{- $isCustomResource := contains "." $g.group }}

// Description: This file stores type information

package {{ $g.version }}

import (
	"github.com/getoutreach/gobox/pkg/log"
	{{- if $isCustomResource }}
	"github.com/getoutreach/services/pkg/k8s/resources"
	{{- else }}
	{{ $g.group | lower }}{{ $g.version }} "k8s.io/api/{{ $g.group | default "core" | lower }}/{{ $g.version }}"
	{{- end }}
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	// Place imports here
	///Block(imports)
{{ file.Block "imports" }}
	///EndBlock(imports)
)

{{- if $isCustomResource }}

// {{ $r.kind }}Spec holds the spec metadata for {{ $r.kind }} resource.
type {{ $r.kind }}Spec struct {
	///Block(spec)
{{ file.Block "spec" }}
	///EndBlock(spec)
}

// Hash returns the hash of all the spec fields, it is used to detect changes in the spec.
// If spec's hash does not change, Reconcile can (and should) be skipped to ensure controller does not
// loop on status-only events.
func (s *{{ $r.kind }}Spec) Hash() (string, error) {
	return resources.Hash(s)
}

// {{ $r.kind }}Status holds the status metadata for {{ $r.kind }} resource.
type {{ $r.kind }}Status struct {
  resources.ResourceStatus

	///Block(status)
{{ file.Block "status" }}
	///EndBlock(status)
}

// {{ $r.kind }} is the schema for the {{ $r.kind }} resource.
// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
type {{ $r.kind }} struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

  // Spec holds the CR's full spec.
 	Spec {{ $r.kind }}Spec   `json:"spec"`

	// Status holds CR's status fields.
	Status {{ $r.kind }}Status   `json:"status"`

	///Block(crFields)
{{ file.Block "crFields" }}
	///EndBlock(crFields)
}

// GetSpec allows reconciler to perform generic operations on
// the spec, such as Hash.
func (r *{{ $r.kind }}) GetSpec() resources.ResourceSpec {
	return &r.Spec
}

// GetStatus returns the emdedded ResourceStatus portion of the status.
func (r *{{ $r.kind }}) GetStatus() *resources.ResourceStatus {
	return &r.Status.ResourceStatus
}

// {{ $r.kind }}List allows list definition of the {{ $r.kind }} resources.
// +kubebuilder:object:root=true
type {{ $r.kind }}List struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []{{ $r.kind }} `json:"items"`
}
{{- else }}
// {{ $r.kind }} is an alias to {{ $g.group | lower }}{{ $g.version }}.{{ $r.kind }}
// +kubebuilder:object:root=true
type {{ $r.kind }} {{ $g.group | lower }}{{ $g.version }}.{{ $r.kind }}

// {{ $r.kind }}List is an alias to {{ $g.group | lower }}{{ $g.version }}.{{ $r.kind }}List
// +kubebuilder:object:root=true
type {{ $r.kind }}List {{ $g.group | lower }}{{ $g.version }}.{{ $r.kind }}List
{{- end }}

// MarshalLog can be used to add resource fields to log, satisfies resources.Resource interface.
func (r *{{ $r.kind }}) MarshalLog(addfield func(key string, value interface{})) {
	addfield("resource.name", r.Name)
	addfield("resource.namespace", r.Namespace)
}

// Define additional types here.
///Block(moreTypes)
{{ file.Block "moreTypes" }}
///EndBlock(moreTypes)

// init registers the custom types with the schema
func init() { //nolint:gochecknoinits // Why: used for registering
	// Register additional types here.
	///Block(registerTypes)
{{ file.Block "registerTypes" }}
	///EndBlock(registerTypes)

	SchemeBuilder.Register(&{{ $r.kind }}{}, &{{ $r.kind }}List{})
}
{{- end }}

{{- $root := . }}
{{- range $_, $g := stencil.Arg "kubernetes.groups" }}
{{- range $_, $r := $g.resources }}
{{ file.Create (printf "api/k8s/%s/%s/%s_types.go" $g.package $g.version ($r.kind | lower)) 0600 now }}
{{ file.SetContents (stencil.ApplyTemplate "api/kubernetes/type" (dict "group" $g "resource" $r)) }}
{{- end }}
{{- end }}
