// Package main had the tests for the templates
package main_test

import (
	"context"
	"os"
	"testing"

	"github.com/getoutreach/stencil-discovery/pkg/discoverytest"
	"github.com/getoutreach/stencil-golang/internal/plugin"
	"github.com/getoutreach/stencil/pkg/stenciltest"
	"github.com/magefile/mage/sh"
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
	st.Args(map[string]interface{}{
		"mixins": []interface{}{"c", "b", "a"}, // These should be sorted alphabetically in the snapshot
	})
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

func TestRenderDependabot(t *testing.T) {
	st := stenciltest.New(t, ".github/dependabot.yml.tpl", libaryTmpls...)
	st.Args(map[string]interface{}{
		"service":           true,
		"serviceActivities": []interface{}{"grpc"},
		"grpcClients":       []interface{}{"node"},
	})
	st.Run(false)
}

func TestBasicGoMod(t *testing.T) {
	st := stenciltest.New(t, "go.mod.tpl", libaryTmpls...)

	p, err := plugin.NewStencilGolangPlugin(context.Background())
	if err != nil {
		t.Fatal(err)
	}

	st.Ext("github.com/getoutreach/stencil-golang", p)
	st.Run(false)
}

func TestMergeGoMod(t *testing.T) {
	st := stenciltest.New(t, "go.mod.tpl", libaryTmpls...)

	p, err := plugin.NewStencilGolangPlugin(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	st.Ext("github.com/getoutreach/stencil-golang", p)

	// HACK: We need to support copying arbitrary files in stenciltest so we
	// don't have to pollute the current working directory with a go.mod file.
	if err := sh.Copy("go.mod", ".snapshots/testdata/go.mod"); err != nil {
		t.Fatal(err)
	}
	defer os.Remove("go.mod")

	st.Run(false)
}

func TestDevenvYaml(t *testing.T) {
	st := stenciltest.New(t, "devenv.yaml.tpl", libaryTmpls...)
	st.Args(map[string]interface{}{
		"dependencies": map[string]interface{}{
			"required": []interface{}{
				"abc",
				"def",
			},
			"optional": []interface{}{
				"ghi",
			},
		},
	})
	st.Run(false)
}

func TestEmptyDevenvYaml(t *testing.T) {
	st := stenciltest.New(t, "devenv.yaml.tpl", libaryTmpls...)
	st.Run(false)
}

func TestDatadogTf(t *testing.T) {
	st := stenciltest.New(t, "monitoring/datadog.tf.tpl", libaryTmpls...)
	st.Args(map[string]interface{}{
		"reportingTeam": "test:team",
		"deployment": map[string]interface{}{
			"environments": []interface{}{
				"staging",
				"production",
			},
			"serviceDomains": []interface{}{
				"bento",
			},
		},
	})
	st.Run(false)
}

func TestGRPCTf(t *testing.T) {
	st := stenciltest.New(t, "monitoring/grpc.tf.tpl", libaryTmpls...)
	st.Ext("github.com/getoutreach/stencil-discovery", &discoverytest.MockPlugin{})
	st.Args(map[string]interface{}{
		"reportingTeam": "test:team",
		"deployment": map[string]interface{}{
			"environments": []interface{}{
				"staging",
				"production",
			},
			"serviceDomains": []interface{}{
				"bento",
			},
		},
		"service": true,
		"serviceActivities": []interface{}{
			"grpc",
		},
	})
	st.Run(false)
}

func TestHTTPTf(t *testing.T) {
	st := stenciltest.New(t, "monitoring/http.tf.tpl", libaryTmpls...)
	st.Args(map[string]interface{}{
		"reportingTeam": "test:team",
		"deployment": map[string]interface{}{
			"environments": []interface{}{
				"staging",
				"production",
			},
			"serviceDomains": []interface{}{
				"bento",
			},
		},
		"service": true,
		"serviceActivities": []interface{}{
			"http",
		},
	})
	st.Run(false)
}

func TestTemporalTf(t *testing.T) {
	st := stenciltest.New(t, "monitoring/temporal.tf.tpl", libaryTmpls...)
	st.Ext("github.com/getoutreach/stencil-discovery", &discoverytest.MockPlugin{})
	st.Args(map[string]interface{}{
		"reportingTeam": "test:team",
		"deployment": map[string]interface{}{
			"environments": []interface{}{
				"staging",
				"production",
			},
			"serviceDomains": []interface{}{
				"bento",
			},
		},
		"service": true,
		"serviceActivities": []interface{}{
			"temporal",
		},
	})
	st.Run(false)
}

func TestSLOsTf(t *testing.T) {
	st := stenciltest.New(t, "monitoring/slos.tf.tpl", libaryTmpls...)
	st.Ext("github.com/getoutreach/stencil-discovery", &discoverytest.MockPlugin{})
	st.Args(map[string]interface{}{
		"reportingTeam": "test:team",
		"terraform.datadog.monitoring.generateSLOs": true,
		"deployment": map[string]interface{}{
			"environments": []interface{}{
				"staging",
				"production",
			},
			"serviceDomains": []interface{}{
				"bento",
			},
		},
		"service": true,
		"serviceActivities": []interface{}{
			"http",
			"grpc",
		},
	})
	st.Run(false)
}
