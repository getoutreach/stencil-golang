{{ file.Skip "Virtual file to generate kubernetes gvk files" }}
{{- define "api/kubernetes/groupversion_info" }}
// {{ stencil.ApplyTemplate "copyright" }} 

// Description: This files stores group information

// +kubebuilder:object:generate=true
// +groupName={{ .Group }}
package {{ .Version }} //nolint:gochecknoglobals // Why: This is on purpose

import (
	"k8s.io/apimachinery/pkg/runtime/schema"
	"sigs.k8s.io/controller-runtime/pkg/scheme"
)

// GroupName is the k8s's group name used in this resource group.
const GroupName = "{{ .Group }}"

// Contains declarations for interacting with this group
var (
	// GroupVersion is group version used to register these objects
	GroupVersion = schema.GroupVersion{Group: GroupName, Version: "{{ .Version }}"}

	// SchemeBuilder is used to add go types to the GroupVersionKind scheme
	SchemeBuilder = &scheme.Builder{GroupVersion: GroupVersion}

	// AddToScheme adds the types in this group-version to the given scheme.
	AddToScheme = SchemeBuilder.AddToScheme
)
{{- end }}

{{- range $g := stencil.Arg "kubernetes.groups" }}
{{ file.Create (printf "api/k8s/%s/%s/groupversion_info.go" $g.Package $g.Version) 0600 now }}
{{ file.SetContents (stencil.ApplyTemplate "api/kubernetes/groupversion_info" $g) }}
{{- end }}
