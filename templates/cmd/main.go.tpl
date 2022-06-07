{{- file.Skip "Using bootstrap main.go for now" }}
{{- /* Breaking changes are required for clerk, temporal, and tollmon integration currently */}}
// {{ stencil.ApplyTemplate "copyright" }}

// Description: This file is the entrypoint for {{ .Config.Name }}.
// Managed: true

// Package main implements the main entrypoint for the {{ .Config.Name }} service.
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
	"github.com/getoutreach/tollmon/pkg/tollgate"

	"{{ stencil.ApplyTemplate "appImportPath" }}/internal/{{ .Config.Name }}"

	// Place any extra imports for your startup code here
	///Block(imports)
{{ file.Block "imports" }}
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

// Place any customized code for your service in this block
///Block(customized)
{{ file.Block "customized" }}
///EndBlock(customized)

{{- $pkgName := stencil.ApplyTemplate "goPackageSafeName" }}
func main() { //nolint: funlen // Why: We can't dwindle this down anymore without adding complexity.
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	env.ApplyOverrides()
	app.SetName("{{ .Config.Name }}")
	defer setMaxProcs(ctx)()

	cfg, err := {{ $pkgName }}.LoadConfig(ctx)
	if err != nil {
		log.Error(ctx, "failed to load config", events.NewErrorInfo(err))
		return
	}
	
	if err := trace.InitTracer(ctx, "{{ .Config.Name }}"); err != nil {
		log.Error(ctx, "tracing failed to start", events.NewErrorInfo(err))
		return
	}
	defer trace.CloseTracer(ctx)

	log.Info(ctx, "starting", app.Info(), cfg, log.F{"app.pid": os.Getpid()})

	// Place any code for your service to run before registering service activities in this block
	///Block(initialization)
{{ file.Block "initialization" }}
	///EndBlock(initialization)

	acts := []async.Runner{
		{{ $pkgName }}.NewShutdownService(),
		&{{ $pkgName }}.NewHTTPService(),
		{{- if has "http" (stencil.Arg "serviceActivities") }}
		&{{ $pkgName }}.NewPublicHTTPService(),
		{{- end }}
		{{- if has "grpc" (stencil.Arg "serviceActivities") }}
		&{{ $pkgName }}.NewGRPCService(),
		{{- end }}
		{{- if has "kafka" (stencil.Arg "serviceActivities") }}
		{{ $pkgName }}.NewKafkaConsumerService(),
		{{- end }}
		{{- if not (stencil.Arg "kubernetes.groups") }}
		{{ $pkgName }}.NewKubernetesService(),
		{{- end }}
		// Place any additional ServiceActivities that your service has built here to have them handled automatically
		///Block(services)
{{ file.Block "services" }}
		///EndBlock(services)
	}

	// Place any code for your service to run during startup in this block
	///Block(startup)
{{ file.Block "startup" }}
	///EndBlock(startup)

	if err := async.RunGroup(acts).Run(ctx); err != nil {
		log.Warn(ctx, "shutting down service", events.NewErrorInfo(err))
	}
}
