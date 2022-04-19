APP := {{ .Config.Name }}
OSS := {{ stencil.Arg "oss" }}
_ := $(shell ./scripts/devbase.sh) 

include .bootstrap/root/Makefile

###Block(targets)
{{ file.Block "targets" }}
###EndBlock(targets)
