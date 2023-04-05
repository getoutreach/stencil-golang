{{- if empty (stencil.Arg "kubernetes.groups") }}
{{- $_ := file.Skip "No Kubernetes groups" }}
{{- else }}
{{- $_ := stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "mixins" (list "kubernetes") }}
{{- end }}
{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
{{- $_ := file.SetPath (printf "deployments/%s/mixins/%s" .Config.Name (base file.Path)) }}
local ok = import 'kubernetes/outreach.libsonnet';
local app = (import 'kubernetes/app.libsonnet').info('{{ .Config.Name }}');
local team = '{{ stencil.Arg "reportingTeam" }}';

{{- $createMutatingWebhook := false }}
{{- $createControllers := false }}
{{- range $g := stencil.Arg "kubernetes.groups" }}
{{- range $r := $g.resources }}
{{- if $r.generate.webhook }}
{{- $createMutatingWebhook = true }}
{{- end }}
{{- if $r.generate.controller }}
{{- $createControllers = true }}
{{- end }}
{{- end }}
{{- end }}

// Please add common_status_properties to all CRDs by adding it to the CRD's status properties obj, e.g.
// properties { custom properties here } +  common_status_properties
// Note: optional time fields are marked as nullable because zero Time{} is marshalled as JSON null.
local common_status_properties = {
  reconcileFailCount: {
    type: 'integer',
  },
  conditions: {
    type: 'array',
    items: {
      type: 'object',
      properties: {
        type: {
          type: 'string',
        },
        status: {
          type: 'string',
        },
        lastTransitionTime: {
          type: 'string',
          format: 'date-time',
        },
        message: {
          type: 'string',
        },
        reason: {
          type: 'string',
        },
      },
    },
  },
};

// Please provide custom resource specs here. We could theoretically generate its code and spec from yaml ... but too much work for now.
// Make will complain about missing specs when new controllers are added.
// <<Stencil::Block(customResources)>>
{{ file.Block "customResources" }}
// <</Stencil::Block>>

local webhooks = {
  {{- if $createMutatingWebhook }}
  // These objects create a certificate for a mutating webhook to use.
  issuer: ok._Object('cert-manager.io/v1', 'Issuer', 'self-signed', namespace=app.namespace) {
    spec: {
      selfSigned: {},
    },
  },
  certificate: ok._Object('cert-manager.io/v1', 'Certificate', app.name, namespace=app.namespace) {
    spec: {
      dnsNames: [
        app.name + '.' + app.namespace + '.svc',
        app.name + '.' + app.namespace + '.svc.cluster.local',
      ],
      issuerRef: {
        kind: $.issuer.kind,
        name: $.issuer.metadata.name,
      },
      secretName: app.name + '-tls',
    },
  },

  // Modify the deployment to include service certificates generated by cert-manager and
  // host the mutating webhook.
  deployment+: {
    spec+: {
      template+: {
        spec+: {
          containers_+:: {
            default+: {
              volumeMounts_+:: {
                'secret-webhook-tls': {
                  mountPath: '/tmp/k8s-webhook-server/serving-certs'
                },
              },
              ports_+:: {
                'https-webhook': { containerPort: 9443 },
              },
            },
          },
          volumes_+:: {
            'secret-webhook-tls': ok.SecretVolume(ok.Secret($.certificate.spec.secretName, $.certificate.metadata.namespace)),
          },
        },
      },
    },
  },

  service+: {
    spec+: {
      ports_+:: {
        'https-webhook': {
          port: 443,
          targetPort: 'https-webhook',
        },
      },
    },
  },

  // These objects register our service as a mutating webhook
  {{- range $g := stencil.Arg "kubernetes.groups" }}
  {{- range $r := $g.resources }}
  {{- if $r.generate.webhook }}
  {{- $fqn := (printf "%s-%s-%s" $g.group ($r.kind | lower) $g.version) }}
  ['mutatingwebhookconfiguration_{{ $fqn | replace "-" "_" }}']: ok._Object('admissionregistration.k8s.io/v1', 'MutatingWebhookConfiguration', app.name+"-{{ $fqn }}") {
    metadata+: {
      annotations: {
        'cert-manager.io/inject-ca-from': $.certificate.metadata.namespace + '/' + $.certificate.metadata.name,
      },
    },
    webhooks: [{
      name: app.name+'.outreach.io',
      rules: [
        {
          apiGroups: ["{{ $g.group }}"],
          apiVersions: ["{{ $g.version }}"],
          operations: ["CREATE"],
          resources: ["{{ $r.kind | lower }}s"],
          scope: "*",
        }
      ],
      clientConfig: {
        service: {
          name: $.service.metadata.name,
          namespace: $.service.metadata.namespace,
          path: '/mutate--{{ $g.version }}-{{ $r.kind | lower }}',
          port: $.service.spec.ports_['https-webhook'].port,
        },
        // Populated by the cert-manager annotation above.
        caBundle: null,
      },
      admissionReviewVersions: ["v1", "v1beta1"],
      sideEffects: 'None',
      timeoutSeconds: 5
    }],
  },
  {{- end }}
  {{- end }}
  {{- end }}
  {{- end }}
};

local controllers = {
  {{- if $createControllers }}
  {{- range $g := stencil.Arg "kubernetes.groups" }}
  {{- range $r := $g.resources }}
  {{- $snakeKind := $r.kind | lower | snakecase }}
  {{- if $r.generate.controller }}
  {{ $snakeKind }} : ok.CRDv1('{{ $r.kind }}', '{{ $g.group }}', 'apiextensions.k8s.io/v1', ['{{ $g.version }}']) {
    metadata+: {
      labels+: {
        reporting_team: team,
        app: app.name,
      },
    },
    // Please provide {{ $snakeKind }}_spec object in the customResources section above.
    spec+: {{ $snakeKind }}_spec,
  },
  {{- end }}
  {{- end }}
  {{- end }}
  {{- end }}
};

local shared = {
  leader_election_role: ok.Role('leader-election', namespace=app.namespace) {
    rules: [
      {
        apiGroups: [
          '',
        ],
        resources: [
          'configmaps',
        ],
        verbs: [
          'get',
          'list',
          'watch',
          'create',
          'update',
          'patch',
          'delete',
        ],
      },
      {
        apiGroups: [
          'coordination.k8s.io',
        ],
        resources: [
          'leases',
        ],
        verbs: [
          'get',
          'list',
          'watch',
          'create',
          'update',
          'patch',
          'delete',
        ],
      },
      {
        apiGroups: [
          '',
        ],
        resources: [
          'events',
        ],
        verbs: [
          'create',
          'patch',
        ],
      },
    ],
  },
  rolebinding: ok.RoleBinding('leader-election', namespace=app.namespace) {
    roleRef_:: $.leader_election_role,
    subjects_:: [$.svc_acct],
  },
  // TODO: Need to generate this based on each core
  // clusterrolebinding: ok.ClusterRoleBinding(app.name) {
  //   roleRef_:: $.role,
  //   subjects_:: [$.svc_acct]
  // },
};

webhooks + controllers + shared