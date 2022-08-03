// Package main had the tests for the templates
package main_test

import (
	"testing"

	"github.com/getoutreach/stencil/pkg/stenciltest"
)

var requiredtmpls = []string{
	"_helpers.tpl",
}

func TestRenderAPIGoSuccess(t *testing.T) {
	// NOTE: 2022-07-06 For the moment, we cannot change the `Name` field of
	// the ServiceManifest used by the `Run()` method in stenciltest, which is
	// why this test does not verify correct handling of odd service names.
	st := stenciltest.New(t, "api/api.go.tpl", requiredtmpls...)
	st.Run(false)
}
