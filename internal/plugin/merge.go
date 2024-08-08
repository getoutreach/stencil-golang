// Copyright 2023 Outreach Corporation. All Rights Reserved.

// Description: provides tools for merging plugins.
package plugin

import (
	"fmt"
	"reflect"

	"github.com/blang/semver/v4"
	"github.com/getoutreach/stencil/pkg/extensions/apiv1"
	"github.com/pkg/errors"
	"golang.org/x/mod/modfile"
)

// MergeGoMod merges the second (right hand) go.mod file into the first
// (left hand) go.mod file. The output of the merge is returned as the
// first return value.
//
// This is designed to be used with the left hand go.mod file being the
// user's go.mod file and the right hand go.mod file being the templated
// go.mod file from templates/go.mod.tpl.
//
// The behavior of the merge is as follows:
//   - Versions from the right go.mod file will be used if the version
//     is greater than the version in the left go.mod file or the module
//     is not present in the left go.mod file. If a module in the left
//     go.mod is newer than the module in the right go.mod, the left
//     version will be used.
//   - Replacements from the right go.mod file will be used if they are
//     not in the left go.mod file. If a replacement in the right go.mod
//     has the same path as a replacement in the left go.mod, the left
//     replacement will be kept. Replacements existing in the left go.mod
//     but not in the right go.mod will be kept.
//   - The go statement from the right go.mod file will always be used over
//     the left go.mod file.
func MergeGoMod(t *apiv1.TemplateFunctionExec) (string, error) { //nolint:funlen // Why: We're OK with this
	// It's safe to assume that the arguments are in the correct order
	// because this is validated by the native extension interface (see
	// plugin.go)
	fileNameLeftInf := t.Arguments[0]
	modFileLeftInf := t.Arguments[1]
	fileNameRightInf := t.Arguments[2]
	modFileRightInf := t.Arguments[3]

	fileNameLeft, ok := fileNameLeftInf.(string)
	if !ok {
		return "", fmt.Errorf("expected left go.mod file name to be of type string, got %s", reflect.TypeOf(fileNameLeftInf).String())
	}

	modFileLeft, ok := modFileLeftInf.(string)
	if !ok {
		return "", fmt.Errorf("expected left go.mod file to be of type string, got %s", reflect.TypeOf(modFileLeftInf).String())
	}

	fileNameRight, ok := fileNameRightInf.(string)
	if !ok {
		return "", fmt.Errorf("expected right go.mod file name to be of type string, got %s", reflect.TypeOf(fileNameRightInf).String())
	}

	modFileRight, ok := modFileRightInf.(string)
	if !ok {
		return "", fmt.Errorf("expected right go.mod file to be of type string, got %s", reflect.TypeOf(modFileRightInf).String())
	}

	leftMod, err := modfile.Parse(fileNameLeft, []byte(modFileLeft), nil)
	if err != nil {
		return "", errors.Wrap(err, "failed to parse left go.mod")
	}

	// Build a map of the left hand module paths to their version.
	leftMods := make(map[string]semver.Version)
	for _, mod := range leftMod.Require {
		v, err := semver.ParseTolerant(mod.Mod.Version)
		if err != nil {
			continue
		}

		leftMods[mod.Mod.Path] = v
	}

	// Build a map of the replaces in the left hand go.mod.
	leftReplaces := make(map[string]*modfile.Replace)
	for _, repl := range leftMod.Replace {
		leftReplaces[repl.Old.Path] = repl
	}

	rightMod, err := modfile.Parse(fileNameRight, []byte(modFileRight), nil)
	if err != nil {
		return "", errors.Wrap(err, "failed to parse right go.mod")
	}

	// Change the left hand module versions if the right hand versions
	// are greater than the left hand ones.
	for _, req := range rightMod.Require {
		rv, err := semver.ParseTolerant(req.Mod.Version)
		if err != nil {
			// Invalid, skip. Go would be yelling about this anyways.
			continue
		}

		// Check if it exists in the left hand go.mod.
		if lv, ok := leftMods[req.Mod.Path]; ok {
			// If the right version is less than the left, skip. We don't want
			// to downgrade.
			if rv.LT(lv) {
				continue
			}
		}

		// The right hand version is either greater than left or isn't
		// present in the left go.mod. Add it to the left hand go.mod.
		if err := leftMod.AddRequire(req.Mod.Path, req.Mod.Version); err != nil {
			return "", errors.Wrapf(err, "failed to add/update dependency '%s'", req.Mod.Path)
		}
	}

	// Add any modules that exist in the right go.mod, but not in the
	// left.
	for _, repl := range rightMod.Replace {
		// If the left go.mod already has a replacement for this module,
		// don't add a replacement for it from the right.
		if _, ok := leftReplaces[repl.Old.Path]; ok {
			continue
		}

		if err := leftMod.AddReplace(repl.Old.Path, repl.Old.Version, repl.New.Path, repl.New.Version); err != nil {
			return "", errors.Wrapf(err, "failed to add replace: %v", repl)
		}
	}

	// Always use the go version from the right hand go.mod
	if err := leftMod.AddGoStmt(rightMod.Go.Version); err != nil {
		return "", errors.Wrap(err, "failed to set go version")
	}

	// Always use the toolchain from the right hand go.mod
	if err := leftMod.AddToolchainStmt(rightMod.Toolchain.Name); err != nil {
		return "", errors.Wrap(err, "failed to set toolchain")
	}

	newBytes, err := leftMod.Format()
	if err != nil {
		return "", errors.Wrap(err, "failed to save generated go.mod")
	}
	return string(newBytes), nil
}
