{{- file.Static }}
module github.com/{{ .Runtime.Box.Org }}/{{ .Config.Name }}

go 1.17

require (
	{{- range $d := (stencil.ApplyTemplate "dependencies" | fromYaml).go }}
	{{ $d.name }} {{ $d.version }}
	{{- end }}
)
