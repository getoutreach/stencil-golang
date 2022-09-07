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
		{{- if .defaultConfig }}
{{ .defaultConfig }}
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

// configuration merging logic
local env_config = if std.objectHas(configurationOverride.environment, app.environment) then configurationOverride.environment[app.environment] else {};
local bento_config = if std.objectHas(configurationOverride.bento, app.bento) then configurationOverride.bento[app.bento] else {};

// configuration is the computed value of this service's
// configuration block.
(configurationOverride.default + env_config + bento_config)
