{{- $_ := file.SetPath (printf "deployments/%s/%s.override.jsonnet" .Config.Name .Config.Name) }}
{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
// {{ stencil.ApplyTemplate "copyright" }}
//
// Description: This file is automatically merged into the '{{ .Config.Name }}.jsonnet' file.
// Configuration should go into the '{{ .Config.Name }}.config.jsonnet' file, or in the relevant
// file in the configs/ directory.
//
// Managed: true

local ok = import 'kubernetes/outreach.libsonnet';
local app = (import 'kubernetes/app.libsonnet').info('{{ .Config.Name }}');
local isDev = (app.environment == 'development' || app.environment == 'local_development');

// Put custom global variables here
// <<Stencil::Block(globalVars)>>
{{ file.Block "globalVars" }}
// <</Stencil::Block>>

// Objects contains kubernetes objects (or resources) that should be created in
// all environments.
// Note: If creating an HPA, you will need to remove the deployment.replica so it does not conflict.
// Ex: deployment+: {spec+: { replicas: null, }, },
local objects = {
	// <<Stencil::Block(override)>>
{{ file.Block "override" }}
	// <</Stencil::Block>>
};

// dev_objects contains kubernetes objects (or resources) that should be created
// ONLY in a development environment. This includes the E2E environment.
local dev_objects = {
	// <<Stencil::Block(devoverride)>>
{{ file.Block "devoverride" }}
	// <</Stencil::Block>>
};

// overrideMixins contains a list of files to include as mixins into
// the override file.
local overrideMixins = [
	// <<Stencil::Block(overrideMixins)>>
{{ file.Block "overrideMixins" }}
	// <</Stencil::Block>>
];

local mergedOverrideMixins = std.foldl(function(x, y) (x + y), overrideMixins, {});

// Custom metrics to be added to allow list
local customMetrics = [
  // <<Stencil::Block(customMetrics)>>
  {{ file.Block "customMetrics" }}
  // <</Stencil::Block>>
];

// Metrics to be excluded from allow list
local excludedMetrics = [
  // <<Stencil::Block(excludeMetrics)>>
  {{ file.Block "excludeMetrics" }}
  // <</Stencil::Block>>
];

local metricsAllowlistOverrides = {
  _metricsAllowlist::
    std.filter(
      function(m) !std.member(excludedMetrics, m),
      super._metricsAllowlist
    ) + customMetrics,

  deployment+: {
  	spec+: {
  		template+: {
  			metadata+: {
  				annotations+: {
  					datadog_prom_instances_:: [
  						super.datadog_prom_instances_[0] {
  							metrics: $._metricsAllowlist,
  						},
  					] + super.datadog_prom_instances_[1:],
  				},
  			},
  		},
  	},
  },
};

mergedOverrideMixins + objects + (if isDev then dev_objects else {}) + metricsAllowlistOverrides
