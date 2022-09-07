{{- $_ := file.SetPath (printf "deployments/%s/%s" .Config.Name (base file.Path)) }}
{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
// {{ stencil.ApplyTemplate "copyright" }}
//
// Description: This file is automatically merged into the '{{ .Config.Name }}.jsonnet' file.
// Configuration should go into the '{{ .Config.Name }}.config.jsonnet' file, or in the relevant
// file in the configs/ directory.
// Managed: true

local ok = import 'kubernetes/outreach.libsonnet';
local app = (import 'kubernetes/app.libsonnet').info('{{ .Config.Name }}');
local isDev = (app.environment == 'development' || app.environment == 'local_development');

// Put custom global variables here
///Block(globalVars)
{{ file.Block "globalVars" }}
///EndBlock(globalVars)

// Objects stores kubernetes objects (or resources) that should be created in
// all environments.
local objects = {
	///Block(override)
{{ file.Block "override" }}
	///EndBlock(override)
};

// dev_objects contains kubernetes objects (or resources) that should be created
// ONLY in a development environment. This includes the E2E environment.
local dev_objects = {
	///Block(devoverride)
{{ file.Block "devoverride" }}
	///EndBlock(devoverride)
};

local overrideMixins = [
	// DEPRECATED: Mixins are automatically included when they exist in the mixins/ directory.
	// if there are more custom jsonnet files, mix them in here
	///Block(overrideMixins)
{{ file.Block "overrideMixins" }}
	///EndBlock(overrideMixins)
];

local mergedOverrideMixins = std.foldl(function(x, y) (x + y), overrideMixins, {});
mergedOverrideMixins + objects + (if (isDev || isLocalDev) then dev_objects else {})
