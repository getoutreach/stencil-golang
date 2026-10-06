version: v1
name: "github.com/getoutreach/{{ .Config.Name }}"
build:
  excludes:
    ## <<Stencil::Block(buf_excludes)>>
    {{ file.Block "buf_excludes" }}
    ## <</Stencil::Block>>
breaking:
