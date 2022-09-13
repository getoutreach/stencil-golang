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
			///Block(defaultResources)
			{{- if file.Block "defaultResources" }}
{{ file.Block "defaultResources" }}
			{{- else }}
			requests: {
				cpu: '100m',
				memory: '100Mi'
			},
			limits: self.requests
			{{- end }}
			///EndBlock(defaultResources)
		},

		// Environment-level resource overrides go here with the 1st-level keys
		// of the object being environment names.
		environment: {
			///Block(environmentResources)
{{ file.Block "environmentResources" }}
			///EndBlock(environmentResources)
		},

		// Cluster-level resource overrides go here with the 1st-level keys of
		// the object being bento names.
		cluster: {
			///Block(clusterResources)
{{ file.Block "clusterResources" }}
			///EndBlock(clusterResources)
		},

		// Bento-level resource overrides go here with the 1st-level keys of the
		// object being bento names.
		bento: {
			///Block(bentoResources)
{{ file.Block "bentoResources" }}
			///EndBlock(bentoResources)
		}
};

// Resource override merging logic.
local env_resources = if std.objectHas(resourcesOverride.environment, app.environment) then resourcesOverride.environment[app.environment] else {};
local cluster_resources = if std.objectHas(resourcesOverride.cluster, app.cluster) then resourcesOverride.cluster[app.cluster] else {};
local bento_resources = if std.objectHas(resourcesOverride.bento, app.bento) then resourcesOverride.bento[app.bento] else {};

// Computing the final resources object.
(resourcesOverride.default + env_resources + cluster_resources + bento_resources)
