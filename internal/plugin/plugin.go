// Copyright 2022 Outreach Corporation. All Rights Reserved.

// Description: provides helpers  for working with Go plugins.

// Package plugin provides helpers  for working with Go plugins.
package plugin

import (
	"context"
	"fmt"
	"reflect"

	"github.com/getoutreach/stencil/pkg/extensions/apiv1"
	"golang.org/x/mod/modfile"
)

// _ ensures that StencilGolangPlugin fits the apiv1.Implementation interface.
var _ apiv1.Implementation = &StencilGolangPlugin{}

// StencilGolangPlugin is a type that implements the apiv1.Implementation interface to
// serve as a stencil plugin.
type StencilGolangPlugin struct{}

// NewStencilGolangPlugin creates and initializes the stencil-golang plugin.
func NewStencilGolangPlugin(ctx context.Context) (*StencilGolangPlugin, error) {
	return &StencilGolangPlugin{}, nil
}

// GetConfig returns the configuration for the StencilGolangPlugin.
func (*StencilGolangPlugin) GetConfig() (*apiv1.Config, error) {
	return &apiv1.Config{}, nil
}

// ExecuteTemplateFunction serves as a router for template functions that the stencil-golang
// plugin exports.
func (*StencilGolangPlugin) ExecuteTemplateFunction(t *apiv1.TemplateFunctionExec) (interface{}, error) {
	switch t.Name {
	case "ParseGoMod":
		fileNameInf := t.Arguments[0]
		modFileInf := t.Arguments[1]

		fileName, ok := fileNameInf.(string)
		if !ok {
			return nil, fmt.Errorf("expected go mod file to be of type string, got %s", reflect.TypeOf(fileNameInf).String())
		}

		modFile, ok := modFileInf.(string)
		if !ok {
			return nil, fmt.Errorf("expected go mod file to be of type string, got %s", reflect.TypeOf(fileNameInf).String())
		}

		return modfile.Parse(fileName, []byte(modFile), nil)
	case "MergeGoMod":
		return MergeGoMod(t)
	default:
		return nil, fmt.Errorf("unknown function %q", t.Name)
	}
}

// GetTemplateFunctions serves as a function catalog for the template functions that the
// stencil-golang plugin exports.
func (*StencilGolangPlugin) GetTemplateFunctions() ([]*apiv1.TemplateFunction, error) {
	return []*apiv1.TemplateFunction{
		{
			Name:              "ParseGoMod",
			NumberOfArguments: 2,
		},
		{
			Name:              "MergeGoMod",
			NumberOfArguments: 4,
		},
	}, nil
}
