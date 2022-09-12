{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
service: {{ stencil.Arg "service" }}
dependencies:
{{- if gt (len (stencil.GetModuleHook "devenv.dependencies.optional")) 0 }}
  optional:
{{- range (stencil.GetModuleHook "devenv.dependencies.optional") }}
    - "{{ . }}"
{{- end }}
{{- else }}
  optional: []
{{- end }}
{{- if gt (len (stencil.GetModuleHook "devenv.dependencies.required")) 0 }}
  required:
{{- range (stencil.GetModuleHook "devenv.dependencies.required") }}
    - "{{ . }}"
{{- end }}
{{- else }}
  required: []
{{- end }}
