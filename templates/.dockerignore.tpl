.git/

# Node modules

node_modules/
{{- if (has "node" .manifest.GRPCClients) }}
api/clients/node/node_modules/
{{- end }}

# Temorary files
.devspace/
bin/

###Block(extras)
{{- if .extras }}
{{ .extras }}
{{- end }}
###EndBlock(extras)
