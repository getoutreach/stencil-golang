APP := {{ .Config.Name }}
OSS := {{ stencil.Arg "oss" }}
_ := $(shell ./scripts/devbase.sh)

include .bootstrap/root/Makefile

{{- range (stencil.GetModuleHook "Makefile.commands") }}
{{ . }}
{{- end }}

## <<Stencil::Block(targets)>>
{{ file.Block "targets" }}
## <</Stencil::Block>>
