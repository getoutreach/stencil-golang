{{ file.Skip "Helper functions for kubernetes templates" }}

# kubernetes.getSettings is hack to share logic between createController
# and createMutatingWebhook because of how variables are scoped in templates.
{{- define "kubernetes.getSettings" }}
{{- $createMutatingWebhook := false }}
{{- $createController := false }}
{{- range $g := stencil.Arg "kubernetes.groups" }}
  {{- range $r := $g.Resources }}
    {{- if $r.Generate.Webhook }}
createMutatingWebhook: true
    {{- end }}
    {{- if $r.Generate.Controller }}
createController: true
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

# kubernetes.createController returns if we should create a controller or not
# Usage: 
#   {{ stencil.ApplyTemplate "kubernetes.createController" }}
#
#  Check if truthy:
#   {{ (eq stencil.ApplyTemplate "kubernetes.createController" "true") }}
{{- define "kubernetes.createController" }}
{{- (stencil.ApplyTemplate "kubernetes.getSettings" | fromYaml).createController }}
{{- end }}

# kubernetes.createMutatingWebhook returns if we should create a mutating webhook or not
# Usage: 
#   {{ stencil.ApplyTemplate "kubernetes.createMutatingWebhook" }}
#
#  Check if truthy:
#   {{ (eq stencil.ApplyTemplate "kubernetes.createMutatingWebhook" "true") }}
{{- define "kubernetes.createMutatingWebhook" }}
{{- (stencil.ApplyTemplate "kubernetes.getSettings" | fromYaml).createMutatingWebhook }}
{{- end }}
