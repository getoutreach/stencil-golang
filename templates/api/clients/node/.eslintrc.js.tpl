{{- /* TODO: DELETE THIS TEMPLATE FILE - replaced by .oxlintrc.json.tpl as part of eslint-to-oxlint migration */ -}}
{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "node" }}
{{ file.Delete }}
