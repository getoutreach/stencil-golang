{{ file.Skip "Virtual file to generate kubernetes type files" }}

{{- define "api/kubernetes/type" }}
{{- $g := .group }}
{{- $r := .resource }}
{{- $isCustomResource := contains "." $g.Group }}
// {{ stencil.ApplyTemplate "copyright" }} 

// Description: This file stores type information

package {{ $g.Version }}

import (
	"github.com/getoutreach/gobox/pkg/log"
	{{- if $isCustomResource }}
	"github.com/getoutreach/services/pkg/k8s/resources"
	{{- else }}
	{{ $g.Group | lower }}{{ $g.Version }} "k8s.io/api/{{ $g.Group | default "core" | lower }}/{{ $g.Version }}"
	{{- end }}
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	// Place imports here
	///Block(imports)
{{ file.Block "imports" }}
	///EndBlock(imports)
)

{{- if $isCustomResource }}

// {{ $r.Kind }}Spec holds the spec metadata for {{ $r.Kind }} resource.
type {{ $r.Kind }}Spec struct {
	///Block(spec)
{{ file.Block "spec" }}
	///EndBlock(spec)
}

// Hash returns the hash of all the spec fields, it is used to detect changes in the spec.
// If spec's hash does not change, Reconcile can (and should) be skipped to ensure controller does not
// loop on status-only events.
func (s *{{ $r.Kind }}Spec) Hash() (string, error) {
	return resources.Hash(s)
}

// {{ $r.Kind }}Status holds the status metadata for {{ $r.Kind }} resource.
type {{ $r.Kind }}Status struct {
  resources.ResourceStatus

	///Block(status)
{{ file.Block "status" }}
	///EndBlock(status)
}

// {{ $r.Kind }} is the schema for the {{ $r.Kind }} resource.
// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
type {{ $r.Kind }} struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

  // Spec holds the CR's full spec.
 	Spec {{ $r.Kind }}Spec   `json:"spec"`

	// Status holds CR's status fields.
	Status {{ $r.Kind }}Status   `json:"status"`

	///Block(crFields)
{{ file.Block "crFields" }}
	///EndBlock(crFields)
}

// GetSpec allows reconciler to perform generic operations on
// the spec, such as Hash.
func (r *{{ $r.Kind }}) GetSpec() resources.ResourceSpec {
	return &r.Spec
}

// GetStatus returns the emdedded ResourceStatus portion of the status.
func (r *{{ $r.Kind }}) GetStatus() *resources.ResourceStatus {
	return &r.Status.ResourceStatus
}

// {{ $r.Kind }}List allows list definition of the {{ $r.Kind }} resources.
// +kubebuilder:object:root=true
type {{ $r.Kind }}List struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []{{ $r.Kind }} `json:"items"`
}
{{- else }}
// {{ $r.Kind }} is an alias to {{ $g.Group | lower }}{{ $g.Version }}.{{ $r.Kind }}
// +kubebuilder:object:root=true
type {{ $r.Kind }} {{ $g.Group | lower }}{{ $g.Version }}.{{ $r.Kind }}

// {{ $r.Kind }}List is an alias to {{ $g.Group | lower }}{{ $g.Version }}.{{ $r.Kind }}List
// +kubebuilder:object:root=true
type {{ $r.Kind }}List {{ $g.Group | lower }}{{ $g.Version }}.{{ $r.Kind }}List
{{- end }}

// MarshalLog can be used to add resource fields to log, satisfies resources.Resource interface.
func (r *{{ $r.Kind }}) MarshalLog(addfield func(key string, value interface{})) {
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

	SchemeBuilder.Register(&{{ $r.Kind }}{}, &{{ $r.Kind }}List{})
}
{{- end }}

{{- range $g := stencil.Arg "kubernetes.groups" }}
{{- range $r := $g.Resources }}
{{ file.Create (printf "api/k8s/%s/%s/%s_types.go" $g.Package $g.Version ($r.Kind | lower)) 0600 now }}
{{ file.SetContents (stencil.ApplyTemplate "api/kubernetes/groupversion_info" (dict "group" $g "resource" $r)) }}
{{- end }}
{{- end }}
