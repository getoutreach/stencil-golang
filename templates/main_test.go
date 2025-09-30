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

// fakeDockerPullRegistry sets the BOX_DOCKER_PULL_IMAGE_REGISTRY environment
// variable to a fake value for the duration of the test.
func fakeDockerPullRegistry(t *testing.T) {
	t.Helper()
	t.Setenv("BOX_DOCKER_PULL_IMAGE_REGISTRY", "registry.example.com/foo")
}

func TestRenderAPIGoSuccess(t *testing.T) {
	// NOTE: 2022-07-06 For the moment, we cannot change the `Name` field of
	// the ServiceManifest used by the `Run()` method in stenciltest, which is
	// why this test does not verify correct handling of odd service names.
	st := stenciltest.New(t, "api/api.go.tpl", libraryTmpls...)
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestOSSCopyright(t *testing.T) {
	st := stenciltest.New(t, "cmd/main.go.tpl", libraryTmpls...)
	st.Args(map[string]any{
		"oss": true,
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestRenderDeploymentConfig(t *testing.T) {
	st := stenciltest.New(t, "deployments/appname/app.config.jsonnet.tpl", libraryTmpls...)
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestRenderDeploymentJsonnet(t *testing.T) {
	st := stenciltest.New(t, "deployments/appname/app.jsonnet.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"mixins": []interface{}{"c", "b", "a"}, // These should be sorted alphabetically in the snapshot
	})
	st.Run(stenciltest.RegenerateSnapshots())
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
	st.Run(stenciltest.RegenerateSnapshots())
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
	st.Run(stenciltest.RegenerateSnapshots())
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
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestRenderDeploymentOverride(t *testing.T) {
	st := stenciltest.New(t, "deployments/appname/app.override.jsonnet.tpl", libraryTmpls...)
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestRenderDeploymentDockerfile(t *testing.T) {
	fakeDockerPullRegistry(t)
	st := stenciltest.New(t, "deployments/appname/Dockerfile.tpl", libraryTmpls...)
	st.Args(map[string]any{
		"service":       true,
		"reportingTeam": "fnd-seal",
		// Setting versions to avoid needing to update snapshots every
		// time default versions change.
		"versions": map[string]any{
			"go":     "1.0",
			"alpine": "3.1",
		},
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestRenderDeploymentDockerfileForCLI(t *testing.T) {
	fakeDockerPullRegistry(t)
	st := stenciltest.New(t, "deployments/appname/Dockerfile.tpl", libraryTmpls...)
	st.Args(map[string]any{
		"service": false,
		"commands": []any{
			"testcli",
		},
		"deployments": map[string]any{
			"buildContainerForCLI": true,
		},
		"reportingTeam": "fnd-seal",
		// Setting versions to avoid needing to update snapshots every
		// time default versions change.
		"versions": map[string]any{
			"go":     "1.0",
			"alpine": "3.1",
		},
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestRenderDependabot(t *testing.T) {
	st := stenciltest.New(t, ".github/dependabot.yml.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"service":           true,
		"serviceActivities": []interface{}{"grpc"},
		"grpcClients":       []interface{}{"node"},
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestBasicGoMod(t *testing.T) {
	st := stenciltest.New(t, "go.mod.tpl", libraryTmpls...)

	p, err := plugin.NewStencilGolangPlugin(context.Background())
	if err != nil {
		t.Fatal(err)
	}

	st.Ext("github.com/getoutreach/stencil-golang", p)
	st.Run(stenciltest.RegenerateSnapshots())
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

	st.Run(stenciltest.RegenerateSnapshots())
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
	st.Run(stenciltest.RegenerateSnapshots())
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
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestEmptyDevenvYaml(t *testing.T) {
	st := stenciltest.New(t, "devenv.yaml.tpl", libraryTmpls...)
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestDevspaceYaml(t *testing.T) {
	fakeDockerPullRegistry(t)
	st := stenciltest.New(t, "devspace.yaml.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"service": true,
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestVSCodeLaunchConfig(t *testing.T) {
	st := stenciltest.New(t, ".vscode/launch.json.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"service": true,
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestGRPCServerRPC(t *testing.T) {
	st := stenciltest.New(t, "internal/appName/rpc/rpc.go.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"service": true,
		"serviceActivities": []interface{}{
			"grpc",
		},
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestGoreleaserYml(t *testing.T) {
	st := stenciltest.New(t, ".goreleaser.yml.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"commands": []interface{}{
			"cmd1",
			"cmd2",
			"cmd3-sub1",
			"cmd3-sub2",
			"cmd4_sub1",
		},
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestRenderGolangcilintYaml(t *testing.T) {
	st := stenciltest.New(t, "scripts/golangci.yml.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"lintroller": "platinum",
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestUrfaveCLIV2(t *testing.T) {
	st := stenciltest.New(t, "cmd/main_cli.go.tpl", libraryTmpls...)
	st.Args(map[string]any{
		"commands": []any{
			"cmd1",
		},
		"versions": map[string]any{
			"urfave-cli": "v2",
		},
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestUrfaveCLIV3(t *testing.T) {
	st := stenciltest.New(t, "cmd/main_cli.go.tpl", libraryTmpls...)
	st.Args(map[string]any{
		"commands": []any{
			"cmd1",
		},
		"versions": map[string]any{
			"urfave-cli": "v3",
		},
	})
	st.Run(stenciltest.RegenerateSnapshots())
}
