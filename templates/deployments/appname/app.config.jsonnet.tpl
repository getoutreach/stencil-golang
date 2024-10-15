{{- $_ := file.SetPath (printf "deployments/%s/%s.config.jsonnet" .Config.Name .Config.Name) }}
{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
// {{ stencil.ApplyTemplate "copyright" }}
//
// Managed: true

local ok = import 'kubernetes/outreach.libsonnet';
local app = (import 'kubernetes/app.libsonnet').info('{{ .Config.Name }}');

// Put custom global variables here
// <<Stencil::Block(globalVars)>>
{{ file.Block "globalVars" }}
// <</Stencil::Block>>

// Configuration override for various environments go here.
local configurationOverride = {
	local this = self,
	// Environment level configuration override goes here.
	// Note: `development` and `local_development` refer to different
	// environments. `development` is _inside_ your local k8s cluster
	// while local_development is read by `devconfig.sh`
	environment+: {
		local_development+: self.development {
			configmap+: {
				data_+:: {
					ListenHost: '127.0.0.1',
					// <<Stencil::Block(localDevelopmentConfig)>>
{{ file.Block "localDevelopmentConfig" }}
					// <</Stencil::Block>>
				},
			},
		},
		development+: {
			configmap+: {
				data_+:: {
					// <<Stencil::Block(developmentConfig)>>
{{ file.Block "developmentConfig" }}
					// <</Stencil::Block>>
				},
			},
		},
		// <<Stencil::Block(environmentConfig)>>
{{ file.Block "environmentConfig" }}
		// <</Stencil::Block>>
	},

	// Bento level configuration override goes here.
	bento+: {
		// <<Stencil::Block(bentoConfig)>>
{{ file.Block "bentoConfig" }}
		// <</Stencil::Block>>
	},

	// Default configuration for all environments and bentos.
	default+: {
		// <<Stencil::Block(defaultConfig)>>
		{{- if file.Block "defaultConfig" }}
{{ file.Block "defaultConfig" }}
		{{- else }}
		configmap+: {
			data_+:: {
      {{- $configmapData := stencil.GetModuleHook "app.config.jsonnet/configmapData" }}
      {{- if $configmapData }}
      {{- range $configmapData }}
      {{- range $k, $v := . }}
      {{ $k }}: {{ $v | quote }},
      {{- end }}
      {{- end }}
      {{- end }}
			},
		},
		{{- end }}
		// <</Stencil::Block>>
	},
};

// configMixins contains a list of files to include as mixins into
// for the configuration. Should be at the path ./configs/<name>.jsonnet
local configMixins = [
	// <<Stencil::Block(configMixins)>>
{{ file.Block "configMixins" }}
	// <</Stencil::Block>>
	{{- $moduleConfigMixins := stencil.GetModuleHook "app.config.jsonnet/config" }}
	{{- if $moduleConfigMixins }}

	// Start module injected configuration
	{{- range $moduleConfigMixins }}
	import './configs/{{ . }}.jsonnet',
	{{- end }}
	// End of module injected configuration
	{{- end }}
];

// config merges the mixins together, and then merges the configurationOverride ontop.
// then env_config is merged ontop, with bento being merged last. The final result is then returned.
local config = (std.foldl(function(x, y) (x + y), configMixins, {}) + configurationOverride);
local env_config = if std.objectHas(config.environment, app.environment) then config.environment[app.environment] else {};
local bento_config = if std.objectHas(config.bento, app.bento) then config.bento[app.bento] else {};

(config.default + env_config + bento_config)
