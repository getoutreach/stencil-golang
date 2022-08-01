{{- $appName  := .Config.Name }}
{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
{{- $_ := file.SetPath (printf "deployments/%s/%s.jsonnet" .Config.Name .Config.Name) }}
// Code managed by {{ .Runtime.Generator }}, DO NOT MODIFY
// MODIFY THE {{ $appName }}.override.jsonnet INSTEAD
local ok = import 'kubernetes/outreach.libsonnet';
local segments = import '../../concourse/segments.libsonnet';
local app = (import 'kubernetes/app.libsonnet').info('{{ $appName }}');
local resources = import './resources.libsonnet';
local appImageRegistry = std.extVar('appImageRegistry');
local isDev = app.environment == 'development' || app.environment == 'local_development';

{{- if not (empty (stencil.Arg "kubernetes.groups")) }}
local k8sMetricsPort = 2019;
local k8sMetricsName = 'k8s_' + app.name;
{{ end }}

local sharedLabels = {
  repo: app.name,
  bento: app.bento,
  reporting_team: '{{ stencil.Arg "reportingTeam" }}',
};

local all = {
  namespace: ok.Namespace(app.namespace) {
    metadata+: {
      annotations+: {
        'iam.amazonaws.com/permitted': '%s_service_role' % app.name,
      },
      labels+: sharedLabels,
    },
  },
  service: ok.Service(app.name, app.namespace) {
    target_pod:: $.deployment.spec.template,
    metadata+: {
      labels+: sharedLabels,
    },
    spec+: {
      local this = self,
      sessionAffinity: 'None',
      type: 'ClusterIP',
      ports_:: {
        {{- if (has "grpc" (stencil.Arg "serviceActivities")) }}
        grpc: {
          port: 5000,
          targetPort: 'grpc',
        },
        {{- end }}
        metrics: {
          port: 8000,
          targetPort: 'http-prom',
        },
        {{- if (has "http" (stencil.Arg "serviceActivities")) }}
        http: {
          port: 8080,
          targetPort: 'http',
        },
        {{- end }}
      },
      ports: ok.mapToNamedList(this.ports_),
    },
  },
  pdb: ok.PodDisruptionBudget(app.name, app.namespace) {
    metadata+: {
      labels: sharedLabels,
    },
    spec+: { maxUnavailable: 1 },
  },
  // Default configuration for the service, managed by bootstrap.
  // all other configuration should be done in the
  // {{ $appName }}.config.jsonnet file
  configmap: ok.ConfigMap('config', app.namespace) {
    metadata+: {
      annotations+: {
        // deploy configmap after vault-secret-operator CRD (sync wave-value of -5)
        'argocd.argoproj.io/sync-wave': '-4',
      },
    },
    local this = self,
    data_:: {},
    data: {
      // We use this.data_ to allow for ez merging in the override.
      ['%s.yaml' % app.name]: std.manifestYamlDoc(this.data_),
    },
  },
  trace_configmap: ok.ConfigMap('config-trace', app.namespace) {
    local this = self,
    data_:: {
      {{- if eq "honeycomb" (stencil.Arg "tracing") }}
      Honeycomb: {
        Enabled: true,
        APIHost: 'https://api.honeycomb.io',
        APIKey: {
          Path: '/run/secrets/outreach.io/honeycomb/apiKey',
        },
        Dataset: if isDev then 'dev' else 'outreach',
        SamplePercent: if isDev then 100 else 1,
      },
      {{- else }}
      OpenTelemetry: {
        Enabled: true,
        Endpoint: 'api.honeycomb.io',
        APIKey: {
          Path: '/run/secrets/outreach.io/honeycomb/apiKey',
        },
        Dataset: if isDev then 'dev' else 'outreach',
        SamplePercent: if isDev then 100 else 1,
      },
      {{- end }}
    },
    data: {
      // We use this.data_ to allow for ez merging in the override.
      'trace.yaml': std.manifestYamlDoc(this.data_),
    },
  },
  fflags_configmap: ok.ConfigMap('fflags-yaml', app.namespace) {
    local this = self,
    data_:: {
      apiKey: {
        Path: '/run/secrets/outreach.io/launchdarkly/sdk-key',
      },
      flagsToAdd: {
        bento: app.bento,
        channel: if isDev then 'dev' else app.channel,
      },
    },
    data: {
      // We use this.data_ to allow for ez merging in the override.
      'fflags.yaml': std.manifestYamlDoc(this.data_),
    },
  },

  deployment: ok.Deployment(app.name, app.namespace) {
    local deployment_volume_mounts = {
      // default configuration files
      ['config-%s' % app.name]: {
        mountPath: '/run/config/outreach.io/%s.yaml' % app.name,
        subPath: '%s.yaml' % app.name,
      },
      'config-trace-volume': {
        mountPath: '/run/config/outreach.io/trace.yaml',
        subPath: 'trace.yaml',
      },
      'fflags-yaml-volume': {
        mountPath: '/run/config/outreach.io/fflags.yaml',
        subPath: 'fflags.yaml',
      },
      // user provided secrets
      {{- range $secret := stencil.Arg "vaultSecrets"}}
      'secret-{{ $secret | base }}-volume' : {
        mountPath: '/run/secrets/outreach.io/{{ $secret | base }}',
      },
      {{- end }}
    },
    metadata+: {
      labels+: sharedLabels,
    },
    spec+: {
      replicas: if isDev then 1 else 2,
      template+: {
        metadata+: {
          {{- if (has "grpc" (stencil.Arg "serviceActivities")) }}
          labels+: sharedLabels {
            'tollgate.outreach.io/scrape': 'true',
            {{- if or (eq "opentelemetry" (stencil.Arg "metrics")) (eq "dual" (stencil.Arg "metrics")) }}
            'opentelemetry.io/scrape': 'true',
            {{- end }}
          },
          {{- else }}
          labels+: sharedLabels {
            {{- if or (eq "opentelemetry" (stencil.Arg "metrics")) (eq "dual" (stencil.Arg "metrics")) }}
            'opentelemetry.io/scrape': 'true',
            {{- end }}
          },
          {{- end }}
          annotations+: {
            {{- if (has "grpc" (stencil.Arg "serviceActivities")) }}
            'tollgate.outreach.io/group': app.name,
            'tollgate.outreach.io/port': '5000',
            {{- end }}
            'iam.amazonaws.com/role': '%s_service_role' % app.name,
            {{- if or (eq "datadog" (stencil.Arg "metrics")) (eq "dual" (stencil.Arg "metrics")) }}
            // https://docs.datadoghq.com/integrations/openmetrics/
            ['ad.datadoghq.com/' + app.name + '.check_names']: '["openmetrics"]',
            ['ad.datadoghq.com/' + app.name + '.init_configs']: '[{}]',
            ['ad.datadoghq.com/' + app.name + '.instances']: std.manifestJsonEx(self.datadog_prom_instances_, '  '),
            datadog_prom_instances_:: [
              {
                prometheus_url: 'http://%%host%%:' +
                                $.deployment.spec.template.spec.containers_.default.ports_['http-prom'].containerPort +
                                '/metrics',
                namespace: app.name,
                metrics: ['*'],
                send_distribution_buckets: true,
              },
            ],
            {{- if not (empty (stencil.Arg "kubernetes.groups")) }}
            ['ad.datadoghq.com/' + k8sMetricsName + '.check_names']: '["openmetrics"]',
            ['ad.datadoghq.com/' + k8sMetricsName + '.init_configs']: '[{}]',
            ['ad.datadoghq.com/' + k8sMetricsName + '.instances']: std.manifestJsonEx(self.k8s_datadog_prom_instances_, '  '),
            k8s_datadog_prom_instances_:: [
              {
                prometheus_url: 'http://%%host%%:' + k8sMetricsPort + '/metrics',
                namespace: app.name,
                metrics: ['*'],
                send_distribution_buckets: true,
              },
            ],
            {{- end }}
            {{- end }}
          },
        },
        spec+: {
          priorityClassName: 'high-priority',
          containers_:: {
            default: ok.Container(app.name) {
              image: '%s/%s:%s' % [appImageRegistry, app.name, app.version],
              imagePullPolicy: 'IfNotPresent',
              volumeMounts_+:: deployment_volume_mounts,
              env_+:: {
                MY_POD_SERVICE_ACCOUNT: ok.FieldRef("spec.serviceAccountName"),
                MY_NAMESPACE: ok.FieldRef('metadata.namespace'),
                MY_POD_NAME: ok.FieldRef('metadata.name'),
                MY_NODE_NAME: ok.FieldRef('spec.nodeName'),
                MY_DEPLOYMENT: app.name,
                MY_ENVIRONMENT: app.environment,
                MY_CLUSTER: app.cluster,
              },
              readinessProbe: {
                httpGet: {
                  path: '/healthz/ready',
                  port: 'http-prom',
                },
                initialDelaySeconds: 5,
                timeoutSeconds: 1,
                periodSeconds: 15,
              },
              livenessProbe: self.readinessProbe {
                initialDelaySeconds: 15,
                httpGet+: {
                  path: '/healthz/live',
                },
              },
              ports_+:: {
                {{- if (has "grpc" (stencil.Arg "serviceActivities")) }}
                grpc: { containerPort: 5000 },
                {{- end }}
                'http-prom': { containerPort: 8000 },
                {{- if (has "http" (stencil.Arg "serviceActivities")) }}
                http: { containerPort: 8080 },
                {{- end }}
              },
              resources: resources,
            },
          },
          volumes_+:: {
            // default configs
            ['config-%s' % app.name]: ok.ConfigMapVolume(ok.ConfigMap('config', app.namespace)),
            'config-trace-volume': ok.ConfigMapVolume(ok.ConfigMap('config-trace', app.namespace)),
            'fflags-yaml-volume': ok.ConfigMapVolume(ok.ConfigMap('fflags-yaml', app.namespace)),

            // user provided secrets
            {{- range $secret := stencil.Arg "vaultSecrets" }}
            'secret-{{ $secret | base }}-volume': ok.SecretVolume(ok.Secret('{{ $secret | base }}', app.namespace)),
            {{- end }}
          },
        },
      },
    },
  },
};

// vaultOperatorSecrets stores vault secrets for production environments
// this is not related to the development vault secrets operator
local vaultOperatorSecrets = {
  {{- range $secretPath := stencil.Arg "vaultSecrets" }}
  {{- $secretName := ($secretPath | base) }}
  'vs-{{ $secretName }}': ok.VaultSecret('{{ $secretName }}', app.namespace) {
    vaultPath_:: '{{ $secretPath }}' % app,
  },
  {{- end }}
};

// These secrets will be included in dev by default, they are fetched from vault.
local developmentSecrets = {
  {{- range $secretPath := stencil.Arg "vaultSecrets" }}
  {{- $secretName := ($secretPath | base) }}
  'vs-{{ $secretName }}': {
    apiVersion: 'ricoberger.de/v1alpha1',
    kind: 'VaultSecret',
    metadata: {
      name: '{{ $secretName | base }}',
      namespace: app.namespace,
    },
    spec: {
      path: '{{ $secretPath }}' % app,
      type: 'Opaque',
    },
  },
  {{- end }}
};

local override = import './{{ $appName }}.override.jsonnet';
local configuration = import './{{ $appName }}.config.jsonnet';

local mixins = [
  {{- range $mixin := concat (stencil.Arg "mixins") (stencil.GetModuleHook "mixins") }}
  import './mixins/{{ $mixin }}.jsonnet',
  {{- end }}
];
local mergedMixins = std.foldl(function(x, y) (x + y), mixins, {});

ok.FilteredList() {
  // Note: configuration overrides the <appName>.override.jsonnet file,
  // which then overrides the objects found in this file.
  // This is done via a simple key merge, and jsonnet object '+:' notation.
  items_+:: all + (if isDev then developmentSecrets else if app.clusterType == 'legacy' then {} else vaultOperatorSecrets) 
  + mergedMixins 
  + override 
  + configuration 
}
