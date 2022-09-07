{{ $_ := file.SetPath (printf "cmd/%s/%s" .Config.Name (base file.Path)) }}
{{- $pkgName := stencil.ApplyTemplate "goPackageSafeName" }}
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
	"github.com/getoutreach/stencil-golang/pkg/serviceactivities/shutdown"
	"github.com/getoutreach/stencil-golang/pkg/serviceactivities/gomaxprocs"

	"{{ stencil.ApplyTemplate "appImportPath" }}/internal/{{ .Config.Name }}"

	// Place any extra imports for your startup code here
	///Block(imports)
{{ file.Block "imports" }}
	///EndBlock(imports)
)

// Place any customized code for your service in this block
//
///Block(customized)
{{ file.Block "customized" }}
///EndBlock(customized)

// main is the entrypoint for the {{ .Config.Name }} service.
func main() { //nolint: funlen // Why: We can't dwindle this down anymore without adding complexity.
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	env.ApplyOverrides()
	app.SetName("{{ .Config.Name }}")

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
	{{- $preInitializationBlock := stencil.GetModuleHook "preInitializationBlock" }}
	{{- if $preInitializationBlock }}

	// Code inserted by modules
		{{- range $preInitializationBlock  }}
	{{ . }}
		{{- end }}
	// End code inserted by modules
	{{- end }}

	// Place any code for your service to run before registering service activities in this block
	///Block(initialization)
{{ file.Block "initialization" }}
	///EndBlock(initialization)
	{{- $postInitializationBlock := stencil.GetModuleHook "postInitializationBlock" }}
	{{- if $postInitializationBlock }}

	// Code inserted by modules
		{{- range $postInitializationBlock  }}
	{{ . }}
		{{- end }}
	// End code inserted by modules
	{{- end }}

	acts := []async.Runner{
		shutdown.New(),
		gomaxprocs.New(),
		{{ $pkgName }}.NewHTTPService(cfg),
		{{- if has "http" (stencil.Arg "serviceActivities") }}
		{{ $pkgName }}.NewPublicHTTPService(cfg),
		{{- end }}
		{{- if has "grpc" (stencil.Arg "serviceActivities") }}
		{{ $pkgName }}.NewGRPCService(cfg),
		{{- end }}
		{{- if has "kafka" (stencil.Arg "serviceActivities") }}
		{{ $pkgName }}.NewKafkaConsumerService(cfg),
		{{- end }}
		{{- if stencil.Arg "kubernetes.groups" }}
		{{ $pkgName }}.NewKubernetesService(cfg),
		{{- end }}
		{{- $svcActs := stencil.GetModuleHook "serviceActivities" }}
		{{- if $svcActs }}

		// Service activities inserted by modules here
			{{- range $svcActs  }}
			{{ . }},
			{{- end }}
		// End service activities inserted by modules
		{{- end }}

		// Place any additional ServiceActivities that your service has built here to have them handled automatically
		//
		///Block(services)
{{ file.Block "services" }}
		///EndBlock(services)
	}

	// Place any code for your service to run during startup in this block
	//
	///Block(startup)
{{ file.Block "startup" }}
	///EndBlock(startup)

	if err := async.RunGroup(acts).Run(ctx); err != nil {
		log.Warn(ctx, "shutting down service", events.NewErrorInfo(err))
	}
}
