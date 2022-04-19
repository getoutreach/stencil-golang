{{ file.Skip "Virtual file to generate CLIs" }}

{{- define "main-cli" }}
// {{ stencil.ApplyTemplate "copyright" }} 

// Description: This file is the entrypoint for the {{ .Config.Name }} CLI
// command for {{ .Config.Name }}.
// Managed: true

package main

import (
	"context"

	oapp "github.com/getoutreach/gobox/pkg/app"
	"github.com/getoutreach/gobox/pkg/exec"
	"github.com/sirupsen/logrus"
	gcli "github.com/getoutreach/gobox/pkg/cli"
	"github.com/urfave/cli/v2"

	// Place any extra imports for your startup code here
	///Block(imports)
{{ file.Block "imports" }}
	///EndBlock(imports)
)

// HoneycombTracingKey gets set by the Makefile at compile-time which is pulled
// down by devconfig.sh.
var HoneycombTracingKey = "NOTSET" //nolint:gochecknoglobals // Why: We can't compile in things as a const.

///Block(honeycombDataset)
{{- if file.Block "honeycombDataset" }}
{{ file.Block "honeycombDataset" }}
{{- else }}

// HoneycombDataset is a constant denoting the dataset that traces should be stored
// in in honeycomb.
const HoneycombDataset = ""
{{- end }}
///EndBlock(honeycombDataset)

///Block(global)
{{ file.Block "global" }}
///EndBlock(global)

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	log := logrus.New()

	///Block(init)
{{ file.Block "init" }}
	///EndBlock(init)

	app := cli.App{
		Version: oapp.Version,
		Name: "{{ .cmdName }}",
		///Block(app)
{{ file.Block "app" }}
		///EndBlock(app)
	}
	app.Flags = []cli.Flag{
		///Block(flags)
{{ file.Block "flags" }}
		///EndBlock(flags)
	}
	app.Commands = []*cli.Command{
		///Block(commands)
{{ file.Block "commands" }}
		///EndBlock(commands)
	}

	///Block(postApp)
{{ file.Block "postApp" }}
	///EndBlock(postApp)

	// Insert global flags, tracing, updating and start the application.
	gcli.HookInUrfaveCLI(ctx, cancel, &app, log, HoneycombTracingKey, HoneycombDataset)
}

{{- end }}

{{ $root := . }}
{{- range := stencil.Arg "commands" }}
{{ file.Create (printf "%s.go" .) 0600 now }}
{{ file.SetContents (stencil.ApplyTemplate "main-cli" (dict "Config" $root.Config "cmdName" . )) }}
{{- end }}
