.git/

# Node modules

node_modules/
{{- if (has "node" (stencil.Arg "grpcClients")) }}
api/clients/node/node_modules/
{{- end }}

# Temorary files
.devspace/
bin/

###Block(extras)
{{ file.Block "extras" }}
###EndBlock(extras)
