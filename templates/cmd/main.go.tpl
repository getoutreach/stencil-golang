// Copyright {{ .currentYear }} Outreach Corporation. All Rights Reserved.

// Description: This file is the entrypoint for {{ .appName }}.
// Managed: true

// Package main implements the main entrypoint for the {{ .appName }} service.
//
// To build this package do:
//
//   make
//
// To run this do:
//
//   ./bin/{{ .appName }}
//
// To run with honeycomb enabled do: (Note: the below section assumes you have go-outreach cloned somewhere.)
//
//    $> push <go-outreach>
//    $> ./scripts/devconfig.sh
//    $> vault kv get -format=json dev/honeycomb/dev-env | jq -cr '.data.data.apiKey' > ~/.outreach/honeycomb.key
//    $> popd
//    $> ./scripts/devconfig.sh
//    $> ./bin/{{ .appName }}
//
package main

import (
	"context"
	"fmt"
	"os"

	"golang.org/x/sync/errgroup"
	"go.uber.org/automaxprocs/maxprocs"

	"github.com/getoutreach/gobox/pkg/app"
	"github.com/getoutreach/gobox/pkg/env"
	"github.com/getoutreach/gobox/pkg/log"
	"github.com/getoutreach/gobox/pkg/events"
	"github.com/getoutreach/gobox/pkg/trace"
	orglife "github.com/getoutreach/orgservice/pkg/lifecycle"
	"github.com/getoutreach/tollmon/pkg/tollgate"

	"github.com/getoutreach/{{ .repo }}/internal/{{ .appName }}"
	{{- if .clerk.Producers }}
	"github.com/getoutreach/{{ .appName }}/internal/clerk/producers"
	{{- end}}
	{{- if or .clerk.Consumers.Basic .clerk.Consumers.CDC }}
	"github.com/getoutreach/{{ .appName }}/internal/clerk/consumers"
	{{- end}}

	// Place any extra imports for your startup code here
	///Block(imports)
	{{- if .imports }}
{{ .imports }}
	{{- end }}
	///EndBlock(imports)
)

// setMaxProcs ensures that container CPU quotas are adhered to if any exist.
func setMaxProcs(ctx context.Context) func() {
	// Set GOMAXPROCS to match the Linux container CPU quota (if any)
	undo, err := maxprocs.Set(maxprocs.Logger(func(m string, args ...interface{}) {
		message := fmt.Sprintf(m, args...)
		log.Info(ctx, "maxprocs.Set", log.F{"message": message})
	}))
	if err != nil {
		log.Error(ctx, "maxprocs.Set", events.NewErrorInfo(err))
		return func(){}
	}
	return undo
}

// serviceActivity defines the interface that runnable services need to adhere to
// in order to be ran by main.
type serviceActivity interface {
	Run(ctx context.Context, config *{{ .underscoreAppName }}.Config) error
	Close(ctx context.Context) error
}

// Place any customized code for your service in this block
///Block(customized)
{{- if .customized }}
{{ .customized }}
{{- else }}
{{- end }}
///EndBlock(customized)

func main() { //nolint: funlen // Why: We can't dwindle this down anymore without adding complexity.
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	env.ApplyOverrides()
	app.SetName("{{ .appName }}")
	defer setMaxProcs(ctx)()

	cfg := {{ .underscoreAppName }}.LoadConfig(ctx)

	if err := trace.InitTracer(ctx, "{{ .appName }}"); err != nil {
		log.Error(ctx, "tracing failed to start", events.NewErrorInfo(err))
		return
	}
	defer trace.CloseTracer(ctx)

	log.Info(ctx, "starting", app.Info(), cfg, log.F{"app.pid": os.Getpid()})

	{{- if .grpc }}
	t := tollgate.New("{{ .appName }}",
		tollgate.WithMonitoringMode(true),
		///Block(tollgateOpts)
		{{- if .tollgateOpts }}
{{ .tollgateOpts }}
		{{- else }}
		tollgate.WithPartitionRules(tollgate.PartitionByOrgGUID),
		{{- end }}
		///EndBlock(tollgateOpts)
	)
	orgLifecycle := orglife.Lifecycle{}
	{{- end }}

	{{- if .clerk.Producers }}

	clerkProducers, err := producers.NewClerkProducers(ctx, {{ .underscoreAppName }}.NewClerkProducersConfig(cfg).GetProducersOpts())
	if err != nil {
		log.Error(ctx, "unable to initialize clerk producers", events.NewErrorInfo(err))
		return
	}
	defer clerkProducers.Close(ctx)
	log.Info(ctx, "successfully initialized clerk producers")
	{{- end }}

	// Place any code for your service to run before registering service activities in this block
	///Block(initialization)
	{{- if .initialization }}
{{ .initialization }}
	{{- end }}
	///EndBlock(initialization)
	
	{{- if or .clerk.Consumers.Basic .clerk.Consumers.CDC }}
	// Add clerk message handler mapping here
	basicClerkProcessors := []*consumers.BasicProcessor{
		///Block(clerkBasicConsumers)
		{{- if .clerkBasicConsumers }}
{{ .clerkBasicConsumers }}
		{{- else }}
		{{- end }}
		///EndBlock(clerkBasicConsumers)
	}
	cdcClerkProcessors := []*consumers.CDCProcessor{
		///Block(clerkCDCConsumers)
		{{- if .clerkCDCConsumers }}
{{ .clerkCDCConsumers }}
		{{- else }}
		{{- end }}
		///EndBlock(clerkCDCConsumers)
	}
	clerkConsumers, err := consumers.NewClerkConsumers(ctx, basicClerkProcessors, cdcClerkProcessors)
	if err != nil {
		log.Error(ctx, "unable to initialize clerk consumers", events.NewErrorInfo(err))
		return
	}
	{{- end }}

	acts := []serviceActivity {
		{{ .underscoreAppName }}.NewShutdownService(),
		&{{ .underscoreAppName }}.HTTPService{},
		{{- if .http }}
		&{{ .underscoreAppName }}.PublicHTTPService{},
		{{- end }}
		{{- if .grpc }}
		&{{ .underscoreAppName }}.GRPCService{
			Tollgate: t,
			OrgService: orglife.New(orgLifecycle.Hooks()),
		},
		{{- end }}
		{{- if .manifest.Temporal }}
		{{ if .manifest.Temporal.Client }}
		&{{ .underscoreAppName }}.WorkerService{},
		{{ end }}
	  {{- end }}
		{{- if .kafka }}
		{{ .underscoreAppName }}.NewKafkaConsumerService(),
		{{- end }}
		{{- if ne (len .manifest.Kubernetes.Groups) 0 }}
		{{ .underscoreAppName }}.NewKubernetesService(),
		{{- end }}
		// Place any additional ServiceActivities that your service has built here to have them handled automatically
		///Block(services)
		{{- if .services }}
{{ .services }}
		{{- end }}
		///EndBlock(services)
		{{- if or .clerk.Consumers.Basic .clerk.Consumers.CDC }}
		clerkConsumers,
		{{- end }}
	}

	// Place any code for your service to run during startup in this block
	///Block(startup)
	{{- if .startup }}
{{ .startup }}
	{{- end }}
	///EndBlock(startup)

	g, ctx := errgroup.WithContext(ctx)
	for idx := range acts {
		act := acts[idx]
		g.Go(func() error{
			defer act.Close(ctx)
			return act.Run(ctx, cfg)
		})
	}
	if err := g.Wait(); err != nil {
		log.Info(ctx, "Closing down service due to", events.NewErrorInfo(err))
	}
}
