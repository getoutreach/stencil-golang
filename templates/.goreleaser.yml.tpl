{{- if not (stencil.Arg "commands") }}
{{ file.Skip "No commands defined" }}
{{- end -}}
# yaml-language-server: $schema=https://goreleaser.com/static/schema.json
before:
  hooks:
    - make dep
builds:
{{- range $cmdName := stencil.Arg "commands" }}
{{- $opts := (dict) }}
{{- if kindIs "map" $cmdName }}
{{- $cmdName = (index (keys $cmdName) 0) }}
{{- $opts = (index . $cmdName | default (dict)) }}
{{- end }}
  - main: ./cmd/{{ $cmdName }}
    id: &name {{ $cmdName }}
    binary: *name
    goos:
      {{- $goosBlockName := (printf "%vGoos" ($cmdName | replace "-" "" | replace "_" "")) }}
      ## <<Stencil::Block({{ $goosBlockName }})>>
      {{- if not (empty (file.Block $goosBlockName)) }}
      {{ (file.Block $goosBlockName) | trim }}
      {{- else }}
      ## Ability to build assets for those OS: linux, darwin
      - linux
      - darwin
      {{- end }}
      ## <</Stencil::Block>>
    goarch:
      {{- $goarchBlockName := (printf "%vGoarch" ($cmdName | replace "-" "" | replace "_" "")) }}
      ## <<Stencil::Block({{ $goarchBlockName }})>>
      {{- if not (empty (file.Block $goarchBlockName)) }}
      {{ (file.Block $goarchBlockName) | trim }}
      {{- else }}
      ## Ability to build assets for those architectures: amd64, arm64
      - amd64
      - arm64
      {{- end }}
      ## <</Stencil::Block>>
    ldflags:
      - '-w -s -X "github.com/getoutreach/gobox/pkg/app.Version=v{{ "{{" }} .Version {{ "}}" }}"'
      {{- if not $opts.delibird }}
      - '-X "main.HoneycombTracingKey={{ "{{" }} .Env.HONEYCOMB_APIKEY {{ "}}" }}"'
      - '-X "main.TeleforkAPIKey={{ "{{" }} .Env.TELEFORK_APIKEY {{ "}}" }}"'
      {{- end }}
    env:
      - CGO_ENABLED={{ stencil.ApplyTemplate "cgoEnabled" | trim }}
      {{- $blockName := (printf "%vAdditionalEnv" ($cmdName | replace "-" "" | replace "_" "")) }}
      ## <<Stencil::Block({{ $blockName }})>>
      {{ (file.Block $blockName) | trim }}
      ## <</Stencil::Block>>
      {{- end }}

archives: []
checksum:
  name_template: 'checksums.txt'
release:
  # We handle releasing via semantic-release
  disable: true
