APP := {{ .Config.Name }}
OSS := {{ stencil.Arg "oss" }}
_ := $(shell ./scripts/devbase.sh) 

include .bootstrap/root/Makefile

## <<Stencil::Block(targets)>>
{{ file.Block "targets" }}
## <</Stencil::Block>>
