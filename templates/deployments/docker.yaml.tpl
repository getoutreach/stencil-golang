{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
{{ .Config.Name }}:
## <<Stencil::Block(customDockerImages)>>
{{ file.Block "customDockerImages" }}
## <</Stencil::Block>>


{{- range $i, $githubAction := stencil.Arg "githubActions" }}
{{ $githubAction.name }}:
  {{- if $githubAction.dockerConfig.buildContext }}
  buildContext: {{ $githubAction.dockerConfig.buildContext }}
  {{- end }}
  {{- if $githubAction.dockerConfig.pushTo }}
  pushTo: {{ $githubAction.dockerConfig.pushTo }}
  {{- end }}
  {{- if $githubAction.dockerConfig.secrets }}
  secrets: {{ $githubAction.dockerConfig.secrets }}
  {{- end }}
  {{- if  $githubAction.dockerConfig.platforms }}
  platforms: {{ $githubAction.dockerConfig.platforms }}
  {{- end }}
{{- end }}
