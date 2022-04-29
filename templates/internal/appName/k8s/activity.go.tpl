{{- $_ := stencil.ApplyTemplate "kubernetes.skipIfNot" }}
{{- $_ := file.SetPath (printf "internal/%s/kubernetes.go" .Config.Name) }}
{{- $root := . }}
{{- $createController := (eq (stencil.ApplyTemplate "kubernetes.createController") "true") }}
{{- $createMutatingWebhook := (eq (stencil.ApplyTemplate "kubernetes.createMutatingWebhook") "true") }}
// {{ stencil.ApplyTemplate "copyright" }} 

// Description: This file implements a kubernetes controller or webhook for {{ .Config.Name }}.

package {{ stencil.ApplyTemplate "goPackageSafeName" }}test //nolint:revive // Why: We allow [-_].

import (
	"context"

	{{- range $g := stencil.Arg "kubernetes.groups" }}
	{{ $pv := printf "%s_%s" $g.package $g.version }}
	api_{{ $pv }} "github.com/getoutreach/{{ $root.Config.Name }}/api/k8s/{{if not (empty $g.package)}}{{ $g.package }}/{{end}}{{ $g.version }}"
	{{- if $createController }}
	ctrl_{{ $pv }} "github.com/getoutreach/{{ $root.Config.Name }}/internal/controllers/{{if not (empty $g.package)}}{{ $g.package }}/{{end}}{{ $g.version }}"
	{{- end }}
	{{- if $createMutatingWebhook }}
	wh_{{ $pv }} "github.com/getoutreach/{{ $root.Config.Name }}/internal/webhooks/{{if not (empty $g.package)}}{{ $g.package }}/{{end}}{{ $g.version }}"
	{{- end }}
	{{- end }}
	"github.com/getoutreach/{{ .Config.Name }}/internal/k8s"

	"github.com/getoutreach/gobox/pkg/app"
	"github.com/getoutreach/gobox/pkg/events"
	"github.com/getoutreach/gobox/pkg/log"
	logadapters "github.com/getoutreach/gobox/pkg/log/adapters"
	ctrl "sigs.k8s.io/controller-runtime"
	"github.com/pkg/errors"
	"k8s.io/apimachinery/pkg/runtime"
	clientgoscheme "k8s.io/client-go/kubernetes/scheme"
	utilruntime "k8s.io/apimachinery/pkg/util/runtime"
	corev1 "k8s.io/api/core/v1"
	coordinationv1 "k8s.io/api/coordination/v1"

	///Block(imports)
{{ file.Block "imports" }}
	///EndBlock(imports)
)

// KubernetesService is the concrete implementation of the serviceActivity interface
// which defines methods to start and stop a service. In this case the service
// being implemented is a kubernetes controller/webhook.
type KubernetesService struct {
	scheme    *runtime.Scheme
	resources []k8s.Resource
}

// NewKubernetesService creates a new KubernetesService instance
// scoped to this particular scheme.
func NewKubernetesService() *KubernetesService {
	return &KubernetesService{
		scheme: runtime.NewScheme(),
	}
}

// Run starts a Kubernetes controller/webhook.
//
// Run returns on context cancellation, on a call to Close, or on failure.
func (s *KubernetesService) Run(ctx context.Context, cfg *Config) error { //nolint: funlen,lll // Why: This function is long for extensibility reasons since it is generated by bootstrap.
	ctrl.SetLogger(logadapters.NewLogrLogger(ctx))

	s.registerSchemes()

	options := ctrl.Options{
		Scheme:         s.scheme,
		Port:           9443,

		// Redirect controller metrics to a dedicated port for this purpose.
		// Same port is also scraped by datadog.
		MetricsBindAddress: ":2019",

		LeaderElection: true,
		///Block(leaderElectionID)
		{{- if file.Block "leaderElectionID" }}
{{ file.Block "leaderElectionID" }}
		{{- else }}
		LeaderElectionID:       "{{ randAlphaNum 10 | lower }}.outreach.io",
		{{- end }}
		///EndBlock(leaderElectionID)
		LeaderElectionNamespace: app.Info().Namespace,
	}

	// Set or override manager options here
	///Block(setOptions)
{{ file.Block "setOptions" }}
	///EndBlock(setOptions)

	mgr, err := ctrl.NewManager(ctrl.GetConfigOrDie(), options)
	if err != nil {
		return errors.Wrap(err, "failed to create manager")
	}

  // Declare the resources.
	{{- range $g := stencil.Arg "kubernetes.groups" }}
	{{- range $r := $g.Resources }}
	{{ $pv := printf "%s_%s" $g.package  $g.version }}
	{{ $var := printf "%s%s" $r.kind ($g.version | title ) }}

	{{- if $r.Generate.Webhook }}
	wh{{ $var }} := &wh_{{ $pv }}.{{ $r.kind }}Webhook{}
	s.resources = append(s.resources, wh{{ $var }})
	{{- end }}
	{{- if $r.Generate.Controller }}
	ctrl{{ $var }} := ctrl_{{ $pv }}.New{{ $r.kind }}Reconciler(
		mgr.GetClient(),
		// Other fields should be initialized in initResources block (see below).
	)
	s.resources = append(s.resources, ctrl{{ $var }})
	{{- end }}
	{{- end }}
	{{- end }}

	// If resources have additional fields, init them here.
	///Block(initResources)
{{ file.Block "initResources" }}
	///EndBlock(initResources)

	for _, r := range s.resources {
		if err := r.Setup(mgr); err != nil {
			return errors.Wrapf(err, "failed to setup a resource for %s/%s", r.version(), r.kind())
		}
	}

	// +kubebuilder:scaffold:builder

	return errors.Wrap(mgr.Start(ctx), "failed to run manager")
}

// registerSchemes registers all schemes
func (s *KubernetesService) registerSchemes() {
	// Register all core objects that we use
	s.scheme.AddKnownTypes(corev1.SchemeGroupVersion,
		&coordinationv1.Lease{},
		&corev1.ConfigMap{},
	)

	{{- /* Only register core types if we're not a core type, otherwise we collide */}}
	{{ $wrote := false }}
	{{- range $g := stencil.Arg "kubernetes.groups" }}
	{{- if and (not $wrote) (not (empty $g.group)) }}
	utilruntime.Must(clientgoscheme.AddToScheme(s.scheme))
	{{- $wrote = true }}
	{{- end }}
	{{- end }}

	{{- range $g := stencil.Arg "kubernetes.groups" }}
	utilruntime.Must(api_{{ $g.package }}_{{ $g.version }}.AddToScheme(s.scheme))
	{{- end }}

	///Block(extraSchemes)
{{ file.Block "extraSchemes" }}
	///EndBlock(extraSchemes)
}

// Close cleans up webhooks and controllers managed by this instance.
func (s *KubernetesService) Close(ctx context.Context) error {
	var lastErr error
	for _, r := range s.resources {
		if err := r.Close(ctx); err != nil {
			log.Error(ctx, "Failed to close the resource", r, events.Err(err))
			lastErr = err
		}
	}

	// could combine multiple errors into one, but it really does not matter as long as those are logged
	return lastErr
}
