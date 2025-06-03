APP := {{ .Config.Name }}
OSS := {{ stencil.Arg "oss" }}
_ := $(shell ./scripts/devbase.sh)

include .bootstrap/root/Makefile

# creates kubernetes manifests from jsonnet files
.PHONY: pre-gogenerate
pre-gogenerate::
	bash ./deployments/generate.sh

{{- range (stencil.GetModuleHook "Makefile.commands") }}
{{ . }}
{{- end }}

## <<Stencil::Block(targets)>>
{{ file.Block "targets" }}
## <</Stencil::Block>>
