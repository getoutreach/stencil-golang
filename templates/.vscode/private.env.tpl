{{- if stencil.Arg "service" }}
MY_NAMESPACE="{{ .Config.Name }}--bento1a"
{{- end }}
{{- range stencil.GetModuleHook "private.env.envVars" }}
{{- range $k, $v := . }}
{{ $k }}={{ $v | quote }}
{{- end }}
{{- end }}
// <<Stencil::Block(vscodeEnvVars)>>
{{ file.Block "vscodeEnvVars" }}
// <</Stencil::Block>>
