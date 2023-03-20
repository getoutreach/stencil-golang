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

import (
	"context"

	oapp "github.com/getoutreach/gobox/pkg/app"
	"github.com/sirupsen/logrus"
	gcli "github.com/getoutreach/gobox/pkg/cli"
	"github.com/urfave/cli/v2"

	// Place any extra imports for your startup code here
	// <<Stencil::Block(imports)>>
{{ file.Block "imports" }}
	// <</Stencil::Block>>
)

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

// HoneycombDataset is a constant denoting the dataset that traces should be stored
// in in honeycomb.
const HoneycombDataset = ""
{{- end }}
// <</Stencil::Block>>

// <<Stencil::Block(global)>>
{{ file.Block "global" }}
// <</Stencil::Block>>

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	log := logrus.New()

	// <<Stencil::Block(init)>>
{{ file.Block "init" }}
	// <</Stencil::Block>>

	app := cli.App{
		Version: oapp.Version,
		Name: "{{ .cmdName }}",
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
	gcli.HookInUrfaveCLI(ctx, cancel, &app, log, HoneycombTracingKey, HoneycombDataset, TeleforkAPIKey)
}

{{- end -}}

{{ $root := . }}
{{- range $i, $v := stencil.Arg "commands" }}

# Options
{{- $shouldGenerateEntrypoint := true }}
{{- $cmdName := $v }}


{{- if kindIs "map" $v }}
# Get the name from the first key in the map.
{{- $cmdName = (index (keys $v) 0) }}
{{- $opts := (index $v $cmdName) }}

# In case the options are not set somehow, set them to an empty map.
{{- if not $opts }}
{{- $opts = (dict) }}
{{- end }}

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
{{ file.SetContents (stencil.ApplyTemplate $templateName (dict "Config" $root.Config "cmdName" $cmdName )) }}
{{- end }}
