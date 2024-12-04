{{- $_ := file.SetPath (printf "cmd/%s/%s" .Config.Name (base file.Path)) }}
{{- $_ := stencil.ApplyTemplate "skipIfNotService" }}
{{- $pkgName := stencil.ApplyTemplate "goPackageSafeName" }}
// {{ stencil.ApplyTemplate "copyright" }}

// Description: This file is the entrypoint for {{ .Config.Name }}.
// Managed: true

// Package main implements the main entrypoint for the {{ .Config.Name }} service.
package main

import (
	"context"
	"os"

	"github.com/getoutreach/gobox/pkg/app"
	"github.com/getoutreach/gobox/pkg/async"
	"github.com/getoutreach/gobox/pkg/env"
	"github.com/getoutreach/gobox/pkg/log"
	"github.com/getoutreach/gobox/pkg/events"
	"github.com/getoutreach/gobox/pkg/trace"
	"github.com/getoutreach/stencil-golang/pkg/serviceactivities/automemlimit"
	"github.com/getoutreach/stencil-golang/pkg/serviceactivities/shutdown"
	"github.com/getoutreach/stencil-golang/pkg/serviceactivities/gomaxprocs"
	"github.com/getoutreach/stencil-golang/pkg/run"
	"github.com/pkg/errors"


	{{- $additionalImports := stencil.GetModuleHook "main/additionalImports" }}
	{{- if $additionalImports }}

	// Code inserted by modules
		{{- range $additionalImports  }}
	{{ . | quote }}
		{{- end }}
	// End code inserted by modules
	{{- end }}

	// Place any extra imports for your startup code here
	// <<Stencil::Block(imports)>>
{{ file.Block "imports" }}
	// <</Stencil::Block>>
)

// Place any customized code for your service in this block
//
// <<Stencil::Block(customized)>>
{{ file.Block "customized" }}
// <</Stencil::Block>>

// dependencies is a conglomerate struct used for injecting dependencies into service
// activities.
type dependencies struct{
  privateHTTP {{ $pkgName }}.PrivateHTTPDependencies
  {{- if has "http" (stencil.Arg "serviceActivities") }}
  publicHTTP {{ $pkgName }}.PublicHTTPDependencies
  {{- end }}
  {{- if has "grpc" (stencil.Arg "serviceActivities") }}
  gRPC {{ $pkgName }}.GRPCDependencies
  {{- end }}
  {{- range stencil.GetModuleHook "main.dependencies" }}
  {{- range $k, $v := . }}
  {{ $k }} {{ $v }}
  {{- end }}
  {{- end }}
  // <<Stencil::Block(customServiceActivityDependencyInjection)>>
{{ file.Block "customServiceActivityDependencyInjection" }}
	// <</Stencil::Block>>
}

// main is the entrypoint for the {{ .Config.Name }} service.
func main() { //nolint: funlen // Why: We can't dwindle this down anymore without adding complexity.
  exitCode := 1
	defer func() {
		if r := recover(); r != nil {
			panic(r)
		}
		os.Exit(exitCode)
	}()

  ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	env.ApplyOverrides()
	app.SetName("{{ .Config.Name }}")

	cfg, err := {{ $pkgName }}.LoadConfig(ctx)
	if err != nil {
		log.Error(ctx, "failed to load config", events.NewErrorInfo(err))
		return
	}

  // Initialize variable for service activity dependency injection.
  var deps dependencies

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
	// <<Stencil::Block(initialization)>>
{{ file.Block "initialization" }}
	// <</Stencil::Block>>
	{{- $postInitializationBlock := stencil.GetModuleHook "postInitializationBlock" }}
	{{- if $postInitializationBlock }}

	// Code inserted by modules
		{{- range $postInitializationBlock  }}
	{{ . }}
		{{- end }}
	// End code inserted by modules
	{{- end }}

	// Place any code for your service to run during startup in this block
	//
	// <<Stencil::Block(startup)>>
{{ file.Block "startup" }}
	// <</Stencil::Block>>
  
  err = run.Run(ctx, "{{ .Config.Name }}", 
		{{- if has "http" (stencil.Arg "serviceActivities") }}
		run.WithRunner("public-http-svc", {{ $pkgName }}.NewPublicHTTPService(cfg, &deps.publicHTTP)),
		{{- end }}
		{{- if has "grpc" (stencil.Arg "serviceActivities") }}
		run.WithRunner("grpc-svc", {{ $pkgName }}.NewGRPCService(cfg, &deps.gRPC)),
		{{- end }}
		{{- if stencil.Arg "kubernetes.groups" }}
		run.WithRunner("kubernetes-svc", {{ $pkgName }}.NewKubernetesService(cfg)),
		{{- end }}
		{{- $svcActs := stencil.GetModuleHook "serviceActivities" }}
		{{- if $svcActs }}
		// Service activities inserted by modules here
			{{- range $svcActs  }}
			run.WithRunner(
        `{{ . }}`, 
        {{ . }}
      ),
	{{- end }}
		// End service activities inserted by modules
		{{- end }}

		// Place any additional ServiceActivities that your service has built here to have them handled automatically
		//
		// <<Stencil::Block(services)>>
{{ file.Block "services" }}
		// <</Stencil::Block>>
	)

  if err == nil {
    exitCode = 0
  }

  log.Error(ctx, err.Error())
}
