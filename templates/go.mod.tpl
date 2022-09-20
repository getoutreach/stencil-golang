{{ file.Skip "Virtual file to generate go.mod" }}
{{- define "go.mod" -}}
module github.com/{{ .Runtime.Box.Org }}/{{ .Config.Name }}

// This is locked to 1.17 to ensure that generics
// are not in use. This will be removed in the near future.
// - https://outreach-io.atlassian.net/wiki/spaces/DT/pages/2475294804
go 1.17

require (
	{{- range $d := (stencil.ApplyTemplate "dependencies" | fromYaml).go }}
	{{ $d.name }} {{ hasPrefix "v" $d.version | ternary "" "v" }}{{ $d.version }}
	{{- end }}
)

{{- end -}}

# Render the go mod file, use it if we don't have an existing go.mod
{{ $newGoMod := (stencil.ApplyTemplate "go.mod") }}
{{ $goModContents := $newGoMod }}
{{ file.Create "go.mod" 0600 now }}

# If the go.mod already exists, merge it with the generated one
# then write it to disk.
{{- if stencil.Exists "go.mod" }}
  {{ $existingGoMod := stencil.ReadFile "go.mod" }}
  {{ $goModContents = (extensions.Call "github.com/getoutreach/stencil-golang.MergeGoMod" "go.mod" $existingGoMod "go.generate.mod" $newGoMod) }}
{{- end }}

# Write out the go.mod
{{ file.SetContents $goModContents }}
