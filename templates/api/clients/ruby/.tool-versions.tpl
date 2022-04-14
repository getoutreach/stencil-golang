ruby {{ .versions.ruby }}
###Block(rubyToolVersions)
{{- if .rubyToolVersions }}
{{ .rubyToolVersions }}
{{- end }}
###EndBlock(rubyToolVersions)
