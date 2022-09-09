{{- $_ := file.SetPath (printf "deployments/%s/%s" .Config.Name (base file.Path)) }}
{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
// {{ stencil.ApplyTemplate "copyright" }}
//
// Managed: true

local ok = import 'kubernetes/outreach.libsonnet';
local app = (import 'kubernetes/app.libsonnet').info('{{ .Config.Name }}');

// Put custom global variables here
///Block(globalVars)
{{ file.Block "globalVars" }}
///EndBlock(globalVars)

// Configuration override for various environments go here.
local configurationOverride = {
	local this = self,
	// Environment level configuration override goes here.
	// Note: `development` and `local_development` refer to different
	// environments. `development` is _inside_ your local k8s cluster
	// while local_development is read by `devconfig.sh`
	environment: {
		local_development: self.development {
			configmap+: {
				data_+:: {
					ListenHost: '127.0.0.1',
					///Block(localDevelopmentConfig)
{{ file.Block "localDevelopmentConfig" }}
					///EndBlock(localDevelopmentConfig)
				},
			},
		},
		development: {
			configmap+: {
				data_+:: {
					///Block(developmentConfig)
{{ file.Block "developmentConfig" }}
					///EndBlock(developmentConfig)
				},
			},
		},
		///Block(environmentConfig)
{{ file.Block "environmentConfig" }}
		///EndBlock(environmentConfig)
	},

	// Bento level configuration override goes here.
	bento: {
		///Block(bentoConfig)
{{ file.Block "bentoConfig" }}
		///EndBlock(bentoConfig)
	},

	// Default configuration for all environments and bentos.
	default: {
		///Block(defaultConfig)
		{{- if file.Block "defaultConfig" }}
{{ file.Block "defaultConfig" }}
		{{- else }}
		configmap+: {
			data_+:: {
			{{- if has "kafka" (stencil.Arg "serviceActivities") }}
				// Change these as needed
				KafkaConsumerGroupID: "{{ .Config.Name | lower | snakecase }}",
				KafkaConsumerTopic: "{{ .Config.Name | lower | snakecase }}",
			{{- end }}
			},
		},
		{{- end }}
		///EndBlock(defaultConfig)
	},
};

// configMixins contains a list of files to include as mixins into
// for the configuration. Should be at the path ./config/<name>.jsonnet
local configMixins = [
	///Block(configMixins)
{{ file.Block "configMixins" }}
	///EndBlock(configMixins)
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
