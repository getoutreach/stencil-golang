module github.com/getoutreach/{{ .repo }}

go {{ GoVersionMajorMinor | default 1.17 }}

require (
	{{- range $d := .bootstrap_dependencies.Golang }}
	{{ $d.Name }} {{ $d.Version }}
	{{- end }}
)
