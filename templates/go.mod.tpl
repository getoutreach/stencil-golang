module github.com/{{ .Runtime.Box.Org }}/{{ .Config.Name }}

go {{ GoVersionMajorMinor | default 1.17 }}

require (
	{{- range $d := (stencil.ApplyTemplate "dependencies" | fromYaml).go }}
	{{ $d.Name }} {{ $d.Version }}
	{{- end }}
)
