{{- if not (stencil.Arg "commands") }}
{{- file.Delete }}
{{- end -}}
# yaml-language-server: $schema=https://goreleaser.com/static/schema.json
before:
  hooks:
    - make dep
{{- $hasCommands := false }}
{{- range $index, $cmdName := stencil.Arg "commands" }}
{{- $opts := (dict) }}
{{- if kindIs "map" $cmdName }}
{{- $cmdName = (index (keys $cmdName) 0) }}
{{- $opts = (index . $cmdName | default (dict)) }}
{{- end }}
{{- if $opts.buildAsset }}
{{- if eq $index 0 }}
{{- $hasCommands = true }}
builds:
{{- end }}
  - main: ./cmd/{{ $cmdName }}
    id: &name {{ $cmdName }}
    binary: *name
    goos:
      {{- $defaultOs := (list "linux" "darwin") }}
      {{- $osList := ($opts.os | default $defaultOs) }}
      {{- range $os := $osList }}
      - {{ $os }}
      {{- end }}
    goarch:
      {{- $defaultArch := (list "arm64" "amd64") }}
      {{- $archList := ($opts.arch | default $defaultArch) }}
      {{- range $arch := $archList }}
      - {{ $arch }}
      {{- end }}
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
{{- end }}
{{- if not $hasCommands }}
{{- file.Delete }}
{{- end -}}


archives: []
checksum:
  name_template: 'checksums.txt'
release:
  # We handle releasing via semantic-release
  disable: true
