dependencies:
{{- if gt (len (stencil.GetModuleHook "devenv.dependencies.optional")) 0 }}
	{{- range (stencil.GetModuleHook "devenv.dependencies.optional") }}
	optional:
		- "{{ . }}"
	{{- end }}
{{- else }}
	optional: []
{{- end }}
{{- if gt (len (stencil.GetModuleHook "devenv.dependencies.required")) 0 }}
	{{- range (stencil.GetModuleHook "devenv.dependencies.required") }}
	required:
		- "{{ . }}"
	{{- end }}
{{- else }}
	required: []
{{- end }}
