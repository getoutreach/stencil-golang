{{- if not (stencil.Arg "commands") }}
{{ file.Skip "No commands defined" }}
{{- end }}
# Documentation for this file: http://goreleaser.com
before:
  hooks:
    - make dep
builds:
{{- range stencil.GetModuleHook "goreleaser_builds" }}
- main: {{ .main }}
	id: &name {{ .id }}
	binary: *name
	{{- if gt (len .goos) 0 }}
	goos:
	{{- range .goos }}
		- {{ . }}
	{{- end }}
	{{- end }}
	{{- if gt (len .goarch) 0 }}
	goarch:
	{{- range .goarch }}
		- {{ . }}
	{{- end }}
	{{- end }}
	{{- if gt (len .ldflags) 0 }}
	ldflags:
	{{- range .ldflags }}
		- {{ . }}
	{{- end }}
	{{- end }}
	{{- if gt (len .env) 0 }}
	env:
	{{- range .env }}
		- {{ . }}
	{{- end }}
	{{- end }}
{{- end }}
{{- range $cmdName := stencil.Arg "commands" }}
- main: ./cmd/{{ $cmdName }}
  id: &name {{ $cmdName }}
  binary: *name
  goos:
  - linux
  - darwin
  goarch:
  - amd64
  - arm64
  ldflags:
   - '-w -s -X "github.com/getoutreach/gobox/pkg/app.Version=v{{ "{{" }} .Version {{ "}}" }}"'
   - '-X "main.HoneycombTracingKey={{ "{{" }} .Env.HONEYCOMB_APIKEY {{ "}}" }}"'
   - '-X "main.TeleforkAPIKey={{ "{{" }} .Env.TELEFORK_APIKEY {{ "}}" }}"'
  env:
  - CGO_ENABLED=0
{{- end }}
archives: []
checksum:
  name_template: 'checksums.txt'
release:
  # We handle releasing via semantic-release
  disable: true
