{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
{{- $_ := file.SetPath (printf "deployments/%s/mixins/%s.jsonnet" .Config.Name (base file.Path)) }}
local ok = import 'kubernetes/outreach.libsonnet';
local app = (import 'kubernetes/app.libsonnet').info('{{ .Config.Name }}');

local isDev = app.environment == 'development' || app.environment == 'local_development';

local dev_objects = {
  pkgcache: ok.PersistentVolumeClaim('pkgcache', app.namespace) {
    storage: '10Gi',
  },
  appcache: ok.PersistentVolumeClaim('appcache', app.namespace) {
    storage: '2Gi',
  },
};

(if isDev then dev_objects else {})
