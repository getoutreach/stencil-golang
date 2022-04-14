APP := {{ .appName }}
OSS := {{ .manifest.OSS }}
_ := $(shell ./scripts/devbase.sh) 

include .bootstrap/root/Makefile

###Block(targets)
{{- if .targets }}
{{ .targets }}
{{- end }}
###EndBlock(targets)
