package main_test

import (
	"context"
	"maps"
	"testing"

	"github.com/getoutreach/stencil-golang/internal/plugin"
	"github.com/getoutreach/stencil/pkg/stenciltest"
)

// stencilArgs provides base arguments which are merged with the
// provided extra stencil Arguments.
func stencilArgs(extraArgs map[string]any) map[string]any {
	args := map[string]any{
		"description":   "stenciled repo",
		"reportingTeam": "org-team",
	}

	maps.Copy(args, extraArgs)

	return args
}

// newStencilTest creates a new stencil test instance with the provided
// template filename and extra arguments merged with the base arguments.
func newStencilTest(t *testing.T, templateFilename string, args map[string]any, helpers ...string) *stenciltest.Template {
	t.Helper()
	allHelpers := append([]string{"_helpers.tpl"}, helpers...)
	st := stenciltest.New(t, templateFilename, allHelpers...)
	st.Args(stencilArgs(args))
	return st
}

// newStencilTestWithGolangPlugin creates a new stencil test instance with the
// stencil-golang plugin extension registered.
func newStencilTestWithGolangPlugin(t *testing.T, templateFilename string, args map[string]any) *stenciltest.Template {
	t.Helper()
	st := newStencilTest(t, templateFilename, args)

	p, err := plugin.NewStencilGolangPlugin(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	st.Ext("github.com/getoutreach/stencil-golang", p)

	return st
}

// assertTemplateSnapshot is a helper to validate a given template against a snapshot.
func assertTemplateSnapshot(t *testing.T, templateFilename string, args map[string]any, helpers ...string) {
	t.Helper()
	st := newStencilTest(t, templateFilename, args, helpers...)
	st.Run(stenciltest.RegenerateSnapshots())
}
