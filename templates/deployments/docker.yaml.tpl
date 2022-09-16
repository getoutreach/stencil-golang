{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
{{ .Config.Name }}:
## <<Stencil::Block(customDockerImages)>>
{{ file.Block "customDockerImages" }}
## <</Stencil::Block>>
