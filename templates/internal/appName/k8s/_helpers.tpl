{{ file.Skip "Helper functions for kubernetes templates" }}

{{- $createMutatingWebhook := false }}
{{- $createController := false }}
{{- range $r := $g.Resources }}
{{- if $r.Generate.Webhook }}
{{- $createMutatingWebhook = true }}
{{- end }}
{{- if $r.Generate.Controller }}
{{- $createController = true }}
{{- end }}
{{- end }}

# kubernetes.createController returns if we should create a controller or not
# Usage: 
#   {{ stencil.ApplyTemplate "kubernetes.createController" }}
#
#  Check if truthy:
#   {{ (eq stencil.ApplyTemplate "kubernetes.createController" "true") }}
{{- define "kubernetes.createController" }}
{{- $createController }}
{{- end }}

# kubernetes.createMutatingWebhook returns if we should create a mutating webhook or not
# Usage: 
#   {{ stencil.ApplyTemplate "kubernetes.createMutatingWebhook" }}
#
#  Check if truthy:
#   {{ (eq stencil.ApplyTemplate "kubernetes.createMutatingWebhook" "true") }}
{{- define "kubernetes.createMutatingWebhook" }}
{{- $createMutatingWebhook }}
{{- end }}
