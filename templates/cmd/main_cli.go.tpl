{{ file.Skip "Virtual file to generate CLIs" }}

{{- define "main-cli-unmanaged" -}}
{{- $_ := file.Static -}}
// {{ stencil.ApplyTemplate "copyright" }}

// Description: This file is the entrypoint for the {{ .cmdName }} CLI
// command for {{ .Config.Name }}.
// Managed: false

// Package main implements the {{ .cmdName }} CLI.
package main

func main() {

}

{{- end }}

{{- define "main-cli" -}}
// {{ stencil.ApplyTemplate "copyright" }}

// Description: This file is the entrypoint for the {{ .cmdName }} CLI
// command for {{ .Config.Name }}.
// Managed: true

package main

{{- $urfaveCommand := "App" }}
{{- $urfaveImport := (cat "github.com/urfave/cli/" (stencil.Arg "versions.urfave-cli")) | nospace }}
{{- $gcliRun := "Run" }}
{{- if eq (stencil.Arg "versions.urfave-cli") "v3" }}
{{- $urfaveCommand = "Command" }}
{{- $urfaveImport = (cat "github.com/urfave/cli/v3") | nospace }}
{{- $gcliRun = "RunV3" }}
{{- end }}

import (
	"context"

	oapp "github.com/getoutreach/gobox/pkg/app"
	"github.com/sirupsen/logrus"
	gcli "github.com/getoutreach/gobox/pkg/cli"
	{{ $urfaveImport | quote }}
	"github.com/getoutreach/gobox/pkg/cfg"

	// Place any extra imports for your startup code here
	// <<Stencil::Block(imports)>>
{{ file.Block "imports" }}
	// <</Stencil::Block>>
)
{{- if not .opts.delibird }}

// HoneycombTracingKey gets set by the Makefile at compile-time which is pulled
// down by devconfig.sh.
var HoneycombTracingKey = "NOTSET" //nolint:gochecknoglobals // Why: We can't compile in things as a const.

// TeleforkAPIKey gets set by the Makefile at compile-time which is pulled
// down by devconfig.sh.
var TeleforkAPIKey = "NOTSET" //nolint:gochecknoglobals // Why: We can't compile in things as a const.

// <<Stencil::Block(honeycombDataset)>>
{{- if file.Block "honeycombDataset" }}
{{ file.Block "honeycombDataset" }}
{{- else }}

// HoneycombDataset is the dataset where traces should be stored in honeycomb.
const HoneycombDataset = ""
{{- end }}
// <</Stencil::Block>>
{{- end }}

// <<Stencil::Block(global)>>
{{ file.Block "global" }}
// <</Stencil::Block>>

// main is the entrypoint for the {{ .cmdName }} CLI.
func main() {
	ctx, cancel := context.WithCancel(context.Background())
	log := logrus.New()

	// <<Stencil::Block(init)>>
{{ file.Block "init" }}
	// <</Stencil::Block>>

	app := cli.{{ $urfaveCommand }}{
		Version: oapp.Version,
		Name: "{{ .cmdName }}",
{{- if eq (stencil.Arg "versions.urfave-cli") "v3" }}
		EnableShellCompletion: true,
{{- end }}
		// <<Stencil::Block(app)>>
{{ file.Block "app" }}
		// <</Stencil::Block>>
	}
	app.Flags = []cli.Flag{
		// <<Stencil::Block(flags)>>
{{ file.Block "flags" }}
		// <</Stencil::Block>>
	}
	app.Commands = []*cli.Command{
		// <<Stencil::Block(commands)>>
{{ file.Block "commands" }}
		// <</Stencil::Block>>
	}

	// <<Stencil::Block(postApp)>>
{{ file.Block "postApp" }}
	// <</Stencil::Block>>

	// Insert global flags, tracing, updating and start the application.
	gcli.{{ $gcliRun }}(ctx, cancel, &app, &gcli.Config{
		Logger:    log,
		Telemetry: gcli.TelemetryConfig{
			{{- if .opts.delibird }}
			UseDelibird: true,
			{{- else }}
			Otel: gcli.TelemetryOtelConfig{
				Dataset:         HoneycombDataset,
				HoneycombAPIKey: cfg.SecretData(HoneycombTracingKey),
			},
			{{- end }}
		},
	})
}

{{- end -}}

{{ $root := . }}
{{- range $i, $v := stencil.Arg "commands" }}

# Options
{{- $shouldGenerateEntrypoint := true }}
{{- $cmdName := $v }}
{{- $opts := (dict) }}

{{- if kindIs "map" $v }}
# Get the name from the first key in the map.
{{- $cmdName = (index (keys $v) 0) }}
{{- $opts = (index $v $cmdName | default (dict)) }}

# Determine if we should generate an entrypoint for this command or not.
{{- if $opts.unmanaged }}
{{- $shouldGenerateEntrypoint = false }}
{{- end }}
{{- end }}

{{- $templateName := "main-cli" }}
{{- if not $shouldGenerateEntrypoint }}
{{- $templateName = "main-cli-unmanaged" }}
{{- end }}

{{ file.Create (printf "cmd/%s/%s.go" $cmdName $cmdName) 0600 now }}
{{ file.SetContents (stencil.ApplyTemplate $templateName (dict "Config" $root.Config "cmdName" $cmdName "opts" $opts )) }}
{{- end }}
