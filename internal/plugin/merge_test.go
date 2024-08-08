// Copyright 2023 Outreach Corporation. All Rights Reserved.

// Description: provides tools for merging plugins.
package plugin

import (
	"fmt"
	"testing"

	"github.com/getoutreach/stencil/pkg/extensions/apiv1"
	"github.com/google/go-cmp/cmp"
	"golang.org/x/mod/modfile"
)

// goMod is a wrapper around modfile.File meant for easier testing
type goMod struct {
	// goVersion is the version of the go statement
	goVersion string

	// toolchain is the value of the toolchain directive, e.g. "go1.22.0"
	toolchain string

	// modules is a map of module path to version
	// (e.g. "github.com/foo/bar" -> "v1.2.3")
	modules map[string]string

	// replacements is a map of module path to replacement path
	// (e.g. "github.com/foo/bar" -> "github.com/baz/bar")
	replacements map[string]string
}

// newGoMod creates a new goMod.
//
// Arguments:
// 1. modules
// 2. replacements
// 3. goVersion
// 4. toolchain
func newGoMod(args ...any) goMod {
	var g goMod

	for i := 0; i < len(args); i++ {
		// skip nil values
		if args[i] == nil {
			continue
		}

		switch i {
		case 0:
			modules, ok := args[i].(map[string]string)
			if !ok {
				panic("expected modules to be of type map[string]string")
			}
			g.modules = modules
		case 1:
			replacements, ok := args[i].(map[string]string)
			if !ok {
				panic("expected replacements to be of type map[string]string")
			}
			g.replacements = replacements
		case 2:
			goVersion, ok := args[i].(string)
			if !ok {
				panic("expected goVersion to be of type string")
			}
			g.goVersion = goVersion
		case 3:
			toolchain, ok := args[i].(string)
			if !ok {
				panic("expected goVersion to be of type string")
			}
			g.toolchain = toolchain
		}
	}

	// Default to a static go version.
	if g.goVersion == "" {
		g.goVersion = "1.19"
	}

	// Default to a static toolchain.
	if g.toolchain == "" {
		g.toolchain = "go1.19.0"
	}

	return g
}

// unmarshalGoMod unmarshals a go.mod file into a goMod.
func unmarshalGoMod(b []byte) goMod {
	mf, err := modfile.Parse("go.output.mod", b, nil)
	if err != nil {
		panic(err)
	}

	g := goMod{goVersion: mf.Go.Version, toolchain: mf.Toolchain.Name}
	for _, req := range mf.Require {
		// Don't initialize unless we need to. Prevents tests from being
		// invalid because of a difference here.
		if g.modules == nil {
			g.modules = make(map[string]string)
		}

		g.modules[req.Mod.Path] = req.Mod.Version
	}

	for _, rep := range mf.Replace {
		if g.replacements == nil {
			g.replacements = make(map[string]string)
		}

		g.replacements[rep.Old.Path] = rep.New.Path
	}

	return g
}

// Marshal marshals the goMod into a go.mod file.
func (g *goMod) Marshal() string {
	// We parse an empty file because otherwise there's some special magic
	// we have to duplicate to create an empty struct.
	mf, err := modfile.Parse("go.empty.mod", []byte(""), nil)
	if err != nil {
		panic(fmt.Sprintf("failed to generate go.mod structure: %v", err))
	}

	if err := mf.AddGoStmt(g.goVersion); err != nil {
		panic(fmt.Sprintf("failed to add go statement: %v", err))
	}

	if err := mf.AddToolchainStmt(g.toolchain); err != nil {
		panic(fmt.Sprintf("failed to add toolchain statement: %v", err))
	}

	for module, version := range g.modules {
		if err := mf.AddRequire(module, version); err != nil {
			panic(
				fmt.Sprintf(
					"failed to add require for module %s@%s: %v",
					module, version, err,
				),
			)
		}
	}

	for module, replacement := range g.replacements {
		if err := mf.AddReplace(module, "", replacement, ""); err != nil {
			panic(
				fmt.Sprintf(
					"failed to add replace for module %s -> %s: %v",
					module, replacement, err,
				),
			)
		}
	}

	b, err := mf.Format()
	if err != nil {
		panic(fmt.Sprintf("failed to format go.mod: %v", err))
	}

	return string(b)
}

func TestMergeGoMod(t *testing.T) {
	type args struct {
		right goMod
		left  goMod
	}
	tests := []struct {
		name    string
		args    args
		want    goMod
		wantErr bool
	}{
		{
			name: "should use right version over left version when right is newer",
			args: args{
				left: newGoMod(map[string]string{
					"github.com/foo/bar": "v1.2.3",
				}),
				right: newGoMod(map[string]string{
					"github.com/foo/bar": "v1.2.4",
				}),
			},
			want: newGoMod(map[string]string{
				"github.com/foo/bar": "v1.2.4",
			}),
		},
		{
			name: "should not use right version when left is newer",
			args: args{
				left: newGoMod(map[string]string{
					"github.com/foo/bar": "v1.2.4",
				}),
				right: newGoMod(map[string]string{
					"github.com/foo/bar": "v1.2.3",
				}),
			},
			want: newGoMod(map[string]string{
				"github.com/foo/bar": "v1.2.4",
			}),
		},
		{
			name: "should add new modules from right",
			args: args{
				left: newGoMod(),
				right: newGoMod(map[string]string{
					"github.com/foo/bar": "v1.2.4",
				}),
			},
			want: newGoMod(map[string]string{
				"github.com/foo/bar": "v1.2.4",
			}),
		},
		{
			name: "should keep replacements from left not in right",
			args: args{
				left: newGoMod(nil, map[string]string{
					"github.com/foo/bar": "../",
				}),
				right: newGoMod(),
			},
			want: newGoMod(nil, map[string]string{
				"github.com/foo/bar": "../",
			}),
		},
		{
			name: "should not modify replacements from left in right",
			args: args{
				left: newGoMod(nil, map[string]string{
					"github.com/foo/bar": "../",
				}),
				right: newGoMod(nil, map[string]string{
					"github.com/foo/bar": "../different",
				}),
			},
			want: newGoMod(nil, map[string]string{
				"github.com/foo/bar": "../",
			}),
		},
		{
			name: "should add new replacements from right if not in left",
			args: args{
				left: newGoMod(),
				right: newGoMod(nil, map[string]string{
					"github.com/foo/bar": "../different",
				}),
			},
			want: newGoMod(nil, map[string]string{
				"github.com/foo/bar": "../different",
			}),
		},
		{
			name: "should use go version from right over left",
			args: args{
				left:  newGoMod(nil, nil, "1.20"),
				right: newGoMod(nil, nil, "1.13"),
			},
			want: newGoMod(nil, nil, "1.13"),
		},
		{
			name: "should use go toolchain from right over left",
			args: args{
				left:  newGoMod(nil, nil, "1.20", "go1.20.5"),
				right: newGoMod(nil, nil, "1.20", "go1.22.5"),
			},
			want: newGoMod(nil, nil, "1.20", "go1.22.5"),
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			gotStr, err := MergeGoMod(&apiv1.TemplateFunctionExec{
				Name: "MergeGoMod",
				Arguments: []interface{}{
					"go.left.mod",
					tt.args.left.Marshal(),
					"go.right.mod",
					tt.args.right.Marshal(),
				},
			})
			if (err != nil) != tt.wantErr {
				t.Errorf("MergeGoMod() error = %v, wantErr %v", err, tt.wantErr)
				return
			}

			got := unmarshalGoMod([]byte(gotStr))
			if diff := cmp.Diff(tt.want, got, cmp.AllowUnexported(goMod{})); diff != "" {
				t.Errorf("MergeGoMod() mismatch (-want +got):\n%s", diff)
			}
		})
	}
}
