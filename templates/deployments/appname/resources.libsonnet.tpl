{{- $_ := file.SetPath (printf "deployments/%s/%s" .Config.Name (base file.Path)) }}
{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
// {{ stencil.ApplyTemplate "copyright" }}
//
// Description: This file contains resource definitions for each instance (bento, environment, or cluster)
// that your service runs in.
//
// Managed: true
local ok = import 'kubernetes/outreach.libsonnet';
local app = (import 'kubernetes/app.libsonnet').info('{{ .Config.Name }}');

local accounts = import './mixins/accounts.env.jsonnet';

// Resource override for various enviornments go here.
//
// If a deployment matches on more than one of the overrides then
// the following precedence is observed:
//
// bento > cluster > environment
local resourcesOverride = {
		local this = self,

		// If there is no match for the deployment it will default to
		// the resources defined here.
		default: {
			// <<Stencil::Block(defaultResources)>>
			{{- if file.Block "defaultResources" }}
{{ file.Block "defaultResources" }}
			{{- else }}
			requests: {
				cpu: '100m',
				memory: '100Mi'
			},
			limits: self.requests
			{{- end }}
			// <</Stencil::Block>>
		},

		// Environment-level resource overrides go here with the 1st-level keys
		// of the object being environment names.
		environment: {
			// <<Stencil::Block(environmentResources)>>
{{ file.Block "environmentResources" }}
			// <</Stencil::Block>>
			local_development: self.development,
				development: {
					requests: {
						cpu: '2',
						memory: '2000Mi',
					},
					limits: self.requests,
				}
			}
		},

		// Cluster-level resource overrides go here with the 1st-level keys of
		// the object being bento names.
		cluster: {
			// <<Stencil::Block(clusterResources)>>
{{ file.Block "clusterResources" }}
			// <</Stencil::Block>>
		},

		// Bento-level resource overrides go here with the 1st-level keys of the
		// object being bento names.
		bento: {
			// <<Stencil::Block(bentoResources)>>
{{ file.Block "bentoResources" }}
			// <</Stencil::Block>>
		}
};

// Resource override merging logic.
local env_resources = if std.objectHas(resourcesOverride.environment, app.environment) then resourcesOverride.environment[app.environment] else {};
local cluster_resources = if std.objectHas(resourcesOverride.cluster, app.cluster) then resourcesOverride.cluster[app.cluster] else {};
local bento_resources = if std.objectHas(resourcesOverride.bento, app.bento) then resourcesOverride.bento[app.bento] else {};

// Computing the final resources object.
(resourcesOverride.default + env_resources + cluster_resources + bento_resources)
