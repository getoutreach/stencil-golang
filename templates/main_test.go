// Package main had the tests for the templates
package main_test

import (
	"context"
	"os"
	"testing"

	"github.com/getoutreach/stencil-golang/internal/plugin"
	"github.com/getoutreach/stencil/pkg/stenciltest"
	"github.com/magefile/mage/sh"
)

var libraryTmpls = []string{
	"_helpers.tpl",
}

const regenerateSnapshots = true

func TestRenderAPIGoSuccess(t *testing.T) {
	// NOTE: 2022-07-06 For the moment, we cannot change the `Name` field of
	// the ServiceManifest used by the `Run()` method in stenciltest, which is
	// why this test does not verify correct handling of odd service names.
	st := stenciltest.New(t, "api/api.go.tpl", libraryTmpls...)
	st.Run(regenerateSnapshots)
}

func TestRenderDeploymentConfig(t *testing.T) {
	st := stenciltest.New(t, "deployments/appname/app.config.jsonnet.tpl", libraryTmpls...)
	st.Run(regenerateSnapshots)
}

func TestRenderDeploymentJsonnet(t *testing.T) {
	st := stenciltest.New(t, "deployments/appname/app.jsonnet.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"mixins": []interface{}{"c", "b", "a"}, // These should be sorted alphabetically in the snapshot
	})
	st.Run(regenerateSnapshots)
}

func TestRenderDeploymentJsonnet_Canary(t *testing.T) {
	st := stenciltest.New(t, "deployments/appname/app.jsonnet.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"reportingTeam": "test:team",
		"deployment": map[string]interface{}{
			"strategy": "canary",
		},
		"service": true,
		"serviceActivities": []interface{}{
			"http",
			"grpc",
		},
		"slack": "hello",
	})
	st.Run(regenerateSnapshots)
}

func TestRenderDeploymentJsonnet_Canary_emptyServiceActivities(t *testing.T) {
	st := stenciltest.New(t, "deployments/appname/app.jsonnet.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"reportingTeam": "test:team",
		"deployment": map[string]interface{}{
			"strategy": "canary",
		},
		"service":           true,
		"serviceActivities": []interface{}{},
		"slack":             "hello",
	})
	st.Run(regenerateSnapshots)
}

func TestRenderDeploymentJsonnetWithHPA(t *testing.T) {
	st := stenciltest.New(t, "deployments/appname/app.jsonnet.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"hpa": map[string]interface{}{
			"enabled":        true,
			"cpuUtilization": 50,
			"scaleDown": map[string]interface{}{
				"stabilizationWindowSeconds": 1200,
			},
			"scaleUp": map[string]interface{}{
				"stabilizationWindowSeconds": 300,
			},
			"metrics": map[string]interface{}{
				"cpu": map[string]interface{}{
					"averageUtilization": 75,
				},
			},
			"env": map[string]interface{}{
				"staging": map[string]interface{}{
					"maxReplicas": 4,
					"minReplicas": 1,
				},
				"production": map[string]interface{}{
					"maxReplicas": 32,
					"minReplicas": 1,
				},
			},
		},
		"enableReloader": true,
	})
	st.Run(regenerateSnapshots)
}

func TestUseKIAMFalse(t *testing.T) {
	st := stenciltest.New(t, "deployments/appname/app.jsonnet.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"aws": map[string]interface{}{
			"useKIAM": false,
		},
	})
	st.Run(true)
}

func TestRenderDeploymentOverride(t *testing.T) {
	st := stenciltest.New(t, "deployments/appname/app.override.jsonnet.tpl", libraryTmpls...)
	st.Run(regenerateSnapshots)
}

func TestRenderDeploymentDockerfile(t *testing.T) {
	st := stenciltest.New(t, "deployments/appname/Dockerfile.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"reportingTeam": "fnd-seal",
		"versions": map[string]interface{}{
			"golang": "1.0",
			"alpine": "3.1",
		},
	})
	st.Run(regenerateSnapshots)
}

func TestRenderDependabot(t *testing.T) {
	st := stenciltest.New(t, ".github/dependabot.yml.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"service":           true,
		"serviceActivities": []interface{}{"grpc"},
		"grpcClients":       []interface{}{"node"},
	})
	st.Run(regenerateSnapshots)
}

func TestBasicGoMod(t *testing.T) {
	st := stenciltest.New(t, "go.mod.tpl", libraryTmpls...)

	p, err := plugin.NewStencilGolangPlugin(context.Background())
	if err != nil {
		t.Fatal(err)
	}

	st.Ext("github.com/getoutreach/stencil-golang", p)
	st.Run(regenerateSnapshots)
}

func TestMergeGoMod(t *testing.T) {
	st := stenciltest.New(t, "go.mod.tpl", libraryTmpls...)

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

	st.Run(regenerateSnapshots)
}

func TestGoModStanzaVersion(t *testing.T) {
	st := stenciltest.New(t, "go.mod.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"go": map[string]interface{}{
			"stanza": "1.19",
		},
	})

	p, err := plugin.NewStencilGolangPlugin(context.Background())
	if err != nil {
		t.Fatal(err)
	}

	st.Ext("github.com/getoutreach/stencil-golang", p)
	st.Run(regenerateSnapshots)
}

func TestDevenvYaml(t *testing.T) {
	st := stenciltest.New(t, "devenv.yaml.tpl", libraryTmpls...)
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
	st.Run(regenerateSnapshots)
}

func TestEmptyDevenvYaml(t *testing.T) {
	st := stenciltest.New(t, "devenv.yaml.tpl", libraryTmpls...)
	st.Run(regenerateSnapshots)
}

func TestDevspaceYaml(t *testing.T) {
	st := stenciltest.New(t, "devspace.yaml.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"service": true,
	})
	st.Run(regenerateSnapshots)
}

func TestVSCodeLaunchConfig(t *testing.T) {
	st := stenciltest.New(t, ".vscode/launch.json.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"service": true,
	})
	st.Run(regenerateSnapshots)
}

func TestGRPCServerRPC(t *testing.T) {
	st := stenciltest.New(t, "internal/appName/rpc/rpc.go.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"service": true,
		"serviceActivities": []interface{}{
			"grpc",
		},
	})
	st.Run(true)
}

func TestIncludeRubyToolVersionsIfRubyGRPCCLient(t *testing.T) {
	st := stenciltest.New(t, "testdata/tool-versions-ruby/.tool-versions.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"grpcClients": []interface{}{"ruby"},
	})
	st.Run(regenerateSnapshots)
}

func TestDontIncludeRubyToolVersionsIfNotRubyGRPCCLient(t *testing.T) {
	st := stenciltest.New(t, "testdata/tool-versions-ruby/.tool-versions.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{})
	st.Run(regenerateSnapshots)
}

func TestGoreleaserYml(t *testing.T) {
	st := stenciltest.New(t, ".goreleaser.yml.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"commands": []interface{}{
			"cmd1",
			"cmd2",
		},
	})
	st.Run(true)
}
