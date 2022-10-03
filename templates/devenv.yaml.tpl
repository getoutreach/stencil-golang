service: {{ stencil.Arg "service" }}
dependencies:
{{- if stencil.GetModuleHook "devenv.dependencies.optional" }}
  optional:
  {{- range (stencil.GetModuleHook "devenv.dependencies.optional") }}
    - "{{ . }}"
  {{- end }}
{{- else }}
  optional:
{{ toYaml (stencil.Arg "dependencies.optional") | indent 4 }}
{{- end }}
{{- if stencil.GetModuleHook "devenv.dependencies.required" }}
  required:
  {{- range (stencil.GetModuleHook "devenv.dependencies.required") }}
    - "{{ . }}"
  {{- end }}
{{- else }}
  required:
{{ toYaml (stencil.Arg "dependencies.required") | indent 4 }}
{{- end }}
