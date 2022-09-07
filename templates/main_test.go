// Package main had the tests for the templates
package main_test

import (
	"testing"

	"github.com/getoutreach/stencil/pkg/stenciltest"
)

var libaryTmpls = []string{
	"_helpers.tpl",
}

func TestRenderAPIGoSuccess(t *testing.T) {
	// NOTE: 2022-07-06 For the moment, we cannot change the `Name` field of
	// the ServiceManifest used by the `Run()` method in stenciltest, which is
	// why this test does not verify correct handling of odd service names.
	st := stenciltest.New(t, "api/api.go.tpl", libaryTmpls...)
	st.Run(false)
}

func TestRenderDeploymentConfig(t *testing.T) {
	st := stenciltest.New(t, "deployments/appname/app.config.jsonnet.tpl", libaryTmpls...)
	st.Run(false)
}

func TestRenderDeploymentJsonnet(t *testing.T) {
	st := stenciltest.New(t, "deployments/appname/app.jsonnet.tpl", libaryTmpls...)
	st.Run(false)
}

func TestRenderDeploymentOverride(t *testing.T) {
	st := stenciltest.New(t, "deployments/appname/app.override.jsonnet.tpl", libaryTmpls...)
	st.Run(false)
}

func TestRenderDeploymentDockerfile(t *testing.T) {
	st := stenciltest.New(t, "deployments/appname/Dockerfile.tpl", libaryTmpls...)
	st.Args(map[string]interface{}{
		"reportingTeam": "fnd-seal",
		"versions": map[string]interface{}{
			"golang": "1.0",
			"alpine": "3.1",
		},
	})
	st.Run(false)
}
