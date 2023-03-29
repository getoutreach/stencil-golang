{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
{{ .Config.Name }}:
## <<Stencil::Block(customDockerImages)>>
{{ file.Block "customDockerImages" }}
## <</Stencil::Block>>

{{- $extraImageConfigHook := (stencil.GetModuleHook "docker/extraImageConfig") }}
{{- range $extraImageConfigHook }}
{{ toYaml .}}
{{- end }}

{{- range $_, $githubActionsArgs := (stencil.GetModuleHook ".github/workflows/actions/docker") }}
{{- range $githubActionName, $githubActionParams := $githubActionsArgs}}
{{ $githubActionName }}:
{{- if $githubActionParams}}
{{ toYaml $githubActionParams | indent 2 }}
{{- end }}
{{ end }}
{{- end }}
