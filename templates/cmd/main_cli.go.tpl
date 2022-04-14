// Copyright {{ .currentYear }} Outreach Corporation. All Rights Reserved.

// Description: This file is the entrypoint for the {{ .cmdName }} CLI
// command for {{ .appName }}.
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
	{{- if .imports }}
{{ .imports }}
	{{- end }}
	///EndBlock(imports)
)

// HoneycombTracingKey gets set by the Makefile at compile-time which is pulled
// down by devconfig.sh.
var HoneycombTracingKey = "NOTSET" //nolint:gochecknoglobals // Why: We can't compile in things as a const.

///Block(honeycombDataset)
{{- if .honeycombDataset }}
{{ .honeycombDataset }}
{{- else }}

// HoneycombDataset is a constant denoting the dataset that traces should be stored
// in in honeycomb.
const HoneycombDataset = ""
{{- end }}
///EndBlock(honeycombDataset)

///Block(global)
{{- if .global }}
{{ .global }}
{{- end }}
///EndBlock(global)

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	log := logrus.New()

	///Block(init)
	{{- if .init }}
{{ .init }}
	{{- end }}
	///EndBlock(init)

	app := cli.App{
		Version: oapp.Version,
		Name: "{{ .cmdName }}",
		///Block(app)
		{{- if .app }}
{{ .app }}
		{{- end }}
		///EndBlock(app)
	}
	app.Flags = []cli.Flag{
		///Block(flags)
		{{- if .flags }}
{{ .flags }}
		{{- end }}
		///EndBlock(flags)
	}
	app.Commands = []*cli.Command{
		///Block(commands)
		{{- if .commands }}
{{ .commands }}
		{{- end }}
		///EndBlock(commands)
	}

	///Block(postApp)
	{{- if .postApp }}
{{ .postApp }}
	{{- end }}
	///EndBlock(postApp)

	// Insert global flags, tracing, updating and start the application.
	gcli.HookInUrfaveCLI(ctx, cancel, &app, log, HoneycombTracingKey, HoneycombDataset)
}
