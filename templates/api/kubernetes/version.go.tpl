{{ file.Skip "Virtual file to generate kubernetes version files" }}

{{- define "api/kubernetes/version" -}}
// {{ stencil.ApplyTemplate "copyright" }}

// Description: This file triggers generation of the types

// Package {{ .version }} contains declarations for interacting with
// the version/group combo provided.
package {{ .version }}

//nolint:lll //Why: Long shell script
//go:generate /usr/bin/env bash -c "pushd ../../..{{if not (empty .package)}}/..{{end}} >/dev/null 2>&1 && ./scripts/shell-wrapper.sh gobin.sh sigs.k8s.io/controller-tools/cmd/controller-gen@v0.14.0 object paths=./api/k8s/{{ .package }}/{{ .version }} && popd >/dev/null 2>&1"
{{ end }}

{{- range $g := stencil.Arg "kubernetes.groups" }}
{{ file.Create (printf "api/k8s/%s/%s/%s.go" $g.package $g.version $g.version) 0600 now }}
{{ file.SetContents (stencil.ApplyTemplate "api/kubernetes/version" $g) }}
{{- end }}
