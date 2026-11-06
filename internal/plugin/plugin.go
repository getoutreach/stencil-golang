// Copyright 2023 Outreach Corporation. All Rights Reserved.

// Description: Provides helpers for working with Go plugins.

// Package plugin provides helpers for working with Go plugins.
package plugin

import (
	"context"
	"errors"
	"fmt"

	"github.com/getoutreach/stencil/pkg/extensions/apiv1"
	"golang.org/x/mod/modfile"
)

// Static errors returned by the plugin's template functions.
var (
	// ErrInvalidArgumentType is returned when a template function receives an
	// argument of an unexpected type.
	ErrInvalidArgumentType = errors.New("invalid argument type")

	// ErrUnknownFunction is returned when an unknown template function is requested.
	ErrUnknownFunction = errors.New("unknown function")
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
func (*StencilGolangPlugin) ExecuteTemplateFunction(t *apiv1.TemplateFunctionExec) (any, error) {
	switch t.Name {
	case "ParseGoMod":
		fileNameInf := t.Arguments[0]
		modFileInf := t.Arguments[1]

		fileName, ok := fileNameInf.(string)
		if !ok {
			return nil, fmt.Errorf("%w: expected go mod file name to be of type string, got %T", ErrInvalidArgumentType, fileNameInf)
		}

		modFile, ok := modFileInf.(string)
		if !ok {
			return nil, fmt.Errorf("%w: expected go mod file to be of type string, got %T", ErrInvalidArgumentType, modFileInf)
		}

		return modfile.Parse(fileName, []byte(modFile), nil)
	case "MergeGoMod":
		return MergeGoMod(t)
	default:
		return nil, fmt.Errorf("%w: %q", ErrUnknownFunction, t.Name)
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
