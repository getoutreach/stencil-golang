// Code managed by Bootstrap - modify only in the blocks
local ok = import 'kubernetes/outreach.libsonnet';
local app = (import 'kubernetes/app.libsonnet').info('{{ .Config.Name }}');

// THESE VALUES ARE DEPRECATED: Use app.<value> instead.
local name = '{{ .Config.Name }}';
local environment = std.extVar('environment');
local bento = std.extVar('bento');
local cluster = std.extVar('cluster');
local namespace = std.extVar('namespace');
// END DEPRECATION

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
      {{- if .defaultResources }}
{{ .defaultResources }}
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
      {{- if .environmentResources }}
{{ .environmentResources }}
      {{- end }}
      ///EndBlock(environmentResources)
    },

    // Cluster-level resource overrides go here with the 1st-level keys of
    // the object being bento names.
    cluster: {
    	///Block(clusterResources)
    	{{- if .clusterResources }}
{{ .clusterResources }}
      {{- end }}
    	///EndBlock(clusterResources)
    },

    // Bento-level resource overrides go here with the 1st-level keys of the
    // object being bento names.
    bento: {
      ///Block(bentoResources)
      {{- if .bentoResources }}
{{ .bentoResources }}
      {{- end }}
      ///EndBlock(bentoResources)
    }
};

// Resource override merging logic.
local env_resources = if std.objectHas(resourcesOverride.environment, app.environment) then resourcesOverride.environment[app.environment] else {};
local cluster_resources = if std.objectHas(resourcesOverride.cluster, app.cluster) then resourcesOverride.cluster[app.cluster] else {};
local bento_resources = if std.objectHas(resourcesOverride.bento, app.bento) then resourcesOverride.bento[app.bento] else {};

// Computing the final resources object.
(resourcesOverride.default + env_resources + cluster_resources + bento_resources)
