# This is an example goreleaser.yaml file with some sane defaults.
# Make sure to check the documentation at http://goreleaser.com
before:
  hooks:
    - make dep
builds:
{{- range $cmdName := .manifest.Commands }}
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
  env:
  - CGO_ENABLED=0
{{- end }}
archives: []
checksum:
  name_template: 'checksums.txt'
{{- if eq .manifest.ReleaseType "semver" }}
release:
  # We handle releasing via semantic-release
  disable: true
{{- else }}
env_files:
  github_token: '~/.outreach/github.token'
changelog:
  sort: asc
  filters:
    exclude:
    - '^(docs|test|build|chore)(\(.+?\))?:'
release:
  github:
    owner: getoutreach
    name: {{ .repo }}
{{- end }}
