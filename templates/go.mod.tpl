{{ file.Skip "Virtual file to generate go.mod" }}
{{- define "go.mod" -}}
module github.com/{{ .Runtime.Box.Org }}/{{ .Config.Name }}

go {{ (stencil.Arg "go.stanza") | default (stencil.ApplyTemplate "goVersion" | trim) }}

require (
	{{- range $d := (stencil.ApplyTemplate "dependencies" | fromYaml).go }}
	{{ $d.name }} {{ $d.version }}
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
