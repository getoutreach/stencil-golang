// Copyright 2023 Outreach Corporation. All Rights Reserved.

package main

import (
	"context"
	"io"

	goboxlog "github.com/getoutreach/gobox/pkg/log"
	"github.com/getoutreach/stencil-golang/internal/plugin"
	"github.com/getoutreach/stencil/pkg/extensions/apiv1"
	"github.com/sirupsen/logrus"
)

func main() {
	// This makes go-plugin very mad
	goboxlog.SetOutput(io.Discard)

	ctx := context.Background()

	p, err := plugin.NewStencilGolangPlugin(ctx)
	if err != nil {
		logrus.WithError(err).Fatal("failed to create extension")
	}

	logr := logrus.New()
	logr.SetLevel(logrus.DebugLevel)
	if err := apiv1.NewExtensionImplementation(p, logr); err != nil {
		logrus.WithError(err).Fatal("failed to start extension")
	}
}
