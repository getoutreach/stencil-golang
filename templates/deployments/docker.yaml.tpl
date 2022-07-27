{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
{{ .Config.Name }}:
###Block(customDockerImages)
{{ file.Block "customDockerImages" }}
###EndBlock(customDockerImages)
