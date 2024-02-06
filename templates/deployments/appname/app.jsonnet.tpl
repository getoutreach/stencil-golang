{{- $appName  := .Config.Name }}
{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
{{- $_ := file.SetPath (printf "deployments/%s/%s.jsonnet" .Config.Name .Config.Name) }}
// {{ stencil.ApplyTemplate "copyright" }}
//
// Managed: true

local ok = import 'kubernetes/outreach.libsonnet';
local segments = import '../../concourse/segments.libsonnet';
local app = (import 'kubernetes/app.libsonnet').info('{{ $appName }}');
local resources = import './resources.libsonnet';
local argo = import 'kubernetes/argo.libsonnet';
local appImageRegistry = std.extVar('appImageRegistry');
local devEmail = std.extVar('dev_email');
local isDev = app.environment == 'development' || app.environment == 'local_development';

{{- if not (empty (stencil.Arg "kubernetes.groups")) }}
local k8sMetricsPort = 2019;
{{ end }}

local sharedLabels = {
	repo: app.name,
	bento: app.bento,
	reporting_team: '{{ stencil.Arg "reportingTeam" }}',
};

{{- if eq "canary" (stencil.Arg "deployment.strategy") }}
local deploymentMetrics = [
  argo.AnalysisMetricDatadog('pod-restart') {
		query:: 'default_zero(sum:kubernetes_state.container.restarts{kube_container_name:%(name)s,kube_namespace:%(namespace)s,role:canary})' % app,
    successCondition: 'default(result, 0) <= {{ stencil.Arg "terraform.datadog.podRestart.thresholds.lowCount" | default 0 }}',
		interval: '1m',
	},
	{{- if (has "http" (stencil.Arg "serviceActivities")) }}
	argo.AnalysisMetricDatadog('http-error-rate') {
		query:: 'moving_rollup(default_zero(100 * count:%(name)s.http_request_seconds{status:5xx,kube_namespace:%(namespace)s,image_tag:%(version)s}.as_count() / count:deploytestservice.http_request_seconds{kube_namespace:%(namespace)s,image_tag:%(version)s}.as_count()), 60, "max")' % app,
    successCondition: 'default(result, 0) < {{ sub 100 (stencil.Arg "terraform.datadog.http.percentiles.lowTraffic" | default 90) }}',
		interval: '1m',
	},
	argo.AnalysisMetricDatadog('http-latency') {
		query:: 'moving_rollup(default_zero(p90:%(name)s.http_request_seconds{kube_namespace:%(namespace)s,image_tag:%(version)s}), 60, "max")' % app,
		successCondition: 'default(result, 0) < {{ stencil.Arg "terraform.datadog.http.latency.thresholds.lowTraffic" | default 2 }}',
		interval: '1m',
	},
	{{- end }}
	{{- if (has "grpc" (stencil.Arg "serviceActivities")) }}
	argo.AnalysisMetricDatadog('grpc-error-rate') {
		query:: 'moving_rollup(default_zero(100 * count:%(name)s.grpc_request_handled{statuscategory:categoryservererror,kube_namespace:%(namespace)s,image_tag:%(version)s}.as_count() / count:%(name)s.grpc_request_handled{kube_namespace:%(namespace)s,image_tag:%(version)s}.as_count()), 60, "max")' % app,
		successCondition: 'default(result, 0) < {{ sub 100 (stencil.Arg "terraform.datadog.grpc.qos.thresholds.lowTraffic" | default 50) }}',
		interval: '1m',
	},
  argo.AnalysisMetricDatadog('grpc-latency') {
		query:: 'moving_rollup(default_zero(p90:%(name)s.grpc_request_handled{kube_namespace:%(namespace)s,image_tag:%(version)s}), 60, "max")' % app,
		successCondition: 'default(result, 0) < {{ stencil.Arg "terraform.datadog.grpc.latency.thresholds.lowTraffic" | default 2 }}',
		interval: '1m',
	},
	{{- end }}
];
{{- end }}

local all = {
	namespace: ok.Namespace(app.namespace) {
		metadata+: {
			annotations+: {
				{{- if stencil.Arg "aws.useKIAM" }}
				'iam.amazonaws.com/permitted': '%s_service_role' % app.name,
				{{- end }}
			},
			labels+: sharedLabels,
		},
	},
	{{- if eq false (stencil.Arg "aws.useKIAM") }}
	svc_acct: ok.ServiceAccount('%s-svc' % app.name, app.namespace) {
		metadata+: {
			labels+: sharedLabels,
			annotations+: {
				'eks.amazonaws.com/role-arn': 'arn:aws:iam::{{ .Runtime.Box.AWS.DefaultAccountID }}:role/%s-%s' % [app.bento, app.name]
			},
		},
	},
  {{- end }}
	service: ok.Service(app.name, app.namespace) {
		target_pod:: $.deployment.spec.template,
		metadata+: {
			labels+: sharedLabels,
      {{- if (stencil.Arg "kubernetes.useTopologyAwareRouting") }}
      annotations+: {
        'service.kubernetes.io/topology-aware-hints': 'Auto',
      },
      {{- end }}
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
	// Default configuration for the service, managed by stencil.
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
			OpenTelemetry: {
				Enabled: true,
				{{- if eq "opentelemetry" (stencil.Arg "tracing") }}
				CollectorEndpoint:  'otel-collector-singleton.monitoring.svc.cluster.local:4317',
				{{- end }}
				Endpoint: 'api.honeycomb.io',
				APIKey: {
					Path: '/run/secrets/outreach.io/honeycomb/apiKey',
				},
				Dataset: if isDev then 'dev' else 'outreach',
				SamplePercent: if isDev then 100 else 0.25,
			},
		} + if isDev then {
			GlobalTags+: {
				DevEmail: devEmail,
			},
		} else {},
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
			} + if isDev then {
				dev_email: devEmail
			} else {},
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
		{{- if not (stencil.Arg "hpa.enabled") }}
			replicas: if isDev then 1 else 2,
		{{- end }}
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
						configmap_hash: $.configmap.md5,
						{{- if (has "grpc" (stencil.Arg "serviceActivities")) }}
						'tollgate.outreach.io/group': app.name,
						'tollgate.outreach.io/port': '5000',
						{{- end }}
            {{- if stencil.Arg "aws.useKIAM" }}
            'iam.amazonaws.com/role': '%s_service_role' % app.name,
            {{- end }}
						{{- if or (eq "datadog" (stencil.Arg "metrics")) (eq "dual" (stencil.Arg "metrics")) }}
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
						// https://docs.datadoghq.com/integrations/openmetrics/
            {{- if (empty (stencil.Arg "kubernetes.groups")) }}
						['ad.datadoghq.com/' + app.name + '.check_names']: '["openmetrics"]',
						['ad.datadoghq.com/' + app.name + '.init_configs']: '[{}]',
						['ad.datadoghq.com/' + app.name + '.instances']: std.manifestJsonEx(self.datadog_prom_instances_, '  '),
            {{- else }}
            // This is duplicated as k8s metrics collection requires a different port as we collect them using the
            // prometheus server hosted in the ControllerManager. Make sure this is kept in sync with the previous block.
						['ad.datadoghq.com/' +  app.name + '.check_names']: '["openmetrics","openmetrics"]',
						['ad.datadoghq.com/' +  app.name + '.init_configs']: '[{}, {}]',
						['ad.datadoghq.com/' +  app.name + '.instances']: std.manifestJsonEx(self.k8s_datadog_prom_instances_, '  '),
						k8s_datadog_prom_instances_:: self.datadog_prom_instances_+[
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
								MY_REGION: app.region,
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
          {{- if (stencil.Arg "kubernetes.useTopologyAwareRouting") }}
          topologySpreadConstraints: [
            {
              maxSkew: 2,
              topologyKey: 'topology.kubernetes.io/zone',
              whenUnsatisfiable: 'ScheduleAnyway',
              labelSelector: {
                matchLabels: {
                  app: app.name,
                },
              },
            },
          ],
          {{- end }}
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

// nonDevelopmentObjects defines objects for staging/production environments.
// Note: The vault secrets here are not related to the development vault secrets operator.
local nonDevelopmentObjects = {
  {{- if stencil.Arg "vaultSecrets" }}
  // VaultSecrets to be deployed
	{{- range $secretPath := stencil.Arg "vaultSecrets" }}
	{{- $secretName := ($secretPath | base) }}
	'vs-{{ $secretName }}': ok.VaultSecret('{{ $secretName }}', app.namespace) {
		vaultPath_:: '{{ $secretPath }}' % app,
	},
	{{- end }}
  {{- end }}

  {{- if eq "canary" (stencil.Arg "deployment.strategy") }}
  // ArgoRollouts objects
	service_canary: ok.Service(app.name + '-canary', app.namespace) {
		target_pod:: $.deployment.spec.template,
		metadata+: {
			labels+: sharedLabels,
		},
		spec+: $.service.spec,
	},
	service_stable: ok.Service(app.name + '-stable', app.namespace) {
		target_pod:: $.deployment.spec.template,
		metadata+: {
			labels+: sharedLabels,
		},
		spec+: $.service.spec
	},
	analysis_template: argo.AnalysisTemplate('metrics', app) {
		metrics:: deploymentMetrics
	},
	canary_deployment: argo.CanaryDeployment(app.name, app.namespace) {
		deploymentRef:: $.deployment,
		canaryService:: $.service_canary,
		stableService:: $.service_stable,
		steps:: (if !isDev then [
			{ setWeight: 25 },
			{ pause: { duration: '5m' } },
			{ setWeight: 50 },
			{ pause: { duration: '5m' } },
			{ setWeight: 75 },
			{ pause: { duration: '5m' } },
		] else []) + [
			{ setWeight: 100 },
		],
		{{- $servicePort := "" }}
		{{- if (has "http" (stencil.Arg "serviceActivities")) }}
		{{- $servicePort = 8080 }}
		{{- end }}
		{{- if (has "grpc" (stencil.Arg "serviceActivities")) }}
		{{- $servicePort = 5000 }}
		{{- end }}
		{{- if $servicePort }}
		servicePort:: {{ $servicePort }},
		{{- end }}
		{{- if stencil.Arg "slack" }}
		notification_success:: {{ stencil.Arg "slack" | squote }},
		notification_failure:: {{ stencil.Arg "slack" | squote }},
		{{- end }}
		backgroundAnalysis:: if !isDev then {
			templates: [
				argo.AnalysisTemplateRef($.analysis_template),
			],
			startingStep: 2,
		},
		metadata+: {
			labels+: sharedLabels,
			annotations+: {
				'link.argocd.argoproj.io/external-link': 'https://argorollouts.%(bento)s.%(region)s.outreach.cloud/rollouts/rollout/%(namespace)s/%(name)s' % app,
			},
		},
		spec+: {
			replicas: if isDev then 1 else 2,
		},
	},
  {{- end }}

  {{- if (stencil.Arg "hpa.enabled") }}
  // HPA configuration/objects
  local hpaReplicasConfig = {
    staging: {
      minReplicas: {{ (stencil.Arg "hpa.env.staging.minReplicas") }},
      maxReplicas: {{ (stencil.Arg "hpa.env.staging.maxReplicas") }},
    },
    production: {
      minReplicas: {{ (stencil.Arg "hpa.env.production.minReplicas") }},
      maxReplicas: {{ (stencil.Arg "hpa.env.production.maxReplicas") }},
    },
  },

  hpa: ok.HorizontalPodAutoscaler(app.name, app.namespace) {
      apiVersion: 'autoscaling/v2',
      target:: $.deployment,
      spec+: {
        minReplicas: hpaReplicasConfig[app.environment].minReplicas,
        maxReplicas: hpaReplicasConfig[app.environment].maxReplicas,
        behavior: {
          {{- if (stencil.Arg "hpa.scaleDown.stabilizationWindowSeconds") }}
          scaleDown: {
            stabilizationWindowSeconds: {{ stencil.Arg "hpa.scaleDown.stabilizationWindowSeconds" }},
          },
          {{- end }}
          {{- if (stencil.Arg "hpa.scaleUp.stabilizationWindowSeconds") }}
          scaleUp: {
            stabilizationWindowSeconds: {{ stencil.Arg "hpa.scaleUp.stabilizationWindowSeconds" }},
          },
          {{- end }}
        },
        {{- if (stencil.Arg "hpa.metrics.cpu.averageUtilization") }}
        metrics: [{
          type: 'Resource',
          resource: {
            name: 'cpu',
            target: {
              type: 'Utilization',
              averageUtilization: {{ stencil.Arg "hpa.metrics.cpu.averageUtilization" }},
            },
          },
        }],
        {{- end }}
      },
    },
  {{- end }}
};

// These secrets will be included in dev by default, they are fetched from vault.
local developmentObjects = {
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

	service+: {
		metadata+: {
			annotations+: {
				// Allow everyone AdminGW gRPCUI access in dev environment
				'outreach.io/admingw-allow-grpc-1000000': '.* Everyone',
			},
		},
	},
};

local override = import './{{ $appName }}.override.jsonnet';
local configuration = import './{{ $appName }}.config.jsonnet';

local mixins = [
	{{- range $mixin := sortAlpha (concat (stencil.Arg "mixins") (stencil.GetModuleHook "mixins")) }}
	import './mixins/{{ $mixin }}.jsonnet',
	{{- end }}
];
local mergedMixins = std.foldl(function(x, y) (x + y), mixins, {});

ok.FilteredList() {
	// Note: configuration overrides the <appName>.override.jsonnet file,
	// which then overrides the objects found in this file.
	// This is done via a simple key merge, and jsonnet object '+:' notation.
	items_+:: all + (if isDev then developmentObjects else if app.clusterType == 'legacy' then {} else nonDevelopmentObjects)
	+ mergedMixins
	+ override
	+ configuration
}
