// Copyright 2022 Outreach Corporation. All Rights Reserved.

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

// MergeGoMod merges two go.mod files together
func MergeGoMod(t *apiv1.TemplateFunctionExec) (string, error) { //nolint:funlen // Why: We're OK with this
	fileNameLeftInf := t.Arguments[0]
	modFileLeftInf := t.Arguments[1]
	fileNameRightInf := t.Arguments[2]
	modFileRightInf := t.Arguments[3]

	fileNameLeft, ok := fileNameLeftInf.(string)
	if !ok {
		return "", fmt.Errorf("expected go mod file to be of type string, got %s", reflect.TypeOf(fileNameLeftInf).String())
	}

	modFileLeft, ok := modFileLeftInf.(string)
	if !ok {
		return "", fmt.Errorf("expected go mod file to be of type string, got %s", reflect.TypeOf(modFileLeftInf).String())
	}

	fileNameRight, ok := fileNameRightInf.(string)
	if !ok {
		return "", fmt.Errorf("expected go mod file to be of type string, got %s", reflect.TypeOf(fileNameRightInf).String())
	}

	modFileRight, ok := modFileRightInf.(string)
	if !ok {
		return "", fmt.Errorf("expected go mod file to be of type string, got %s", reflect.TypeOf(modFileRightInf).String())
	}

	origMod, err := modfile.Parse(fileNameLeft, []byte(modFileLeft), nil)
	if err != nil {
		return "", errors.Wrap(err, "failed to parse left go.mod")
	}

	originalModHM := make(map[string]semver.Version)
	for _, mod := range origMod.Require {
		v, err := semver.ParseTolerant(mod.Mod.Version)
		if err != nil {
			continue
		}

		originalModHM[mod.Mod.Path] = v
	}

	templateMod, err := modfile.Parse(fileNameRight, []byte(modFileRight), nil)
	if err != nil {
		return "", errors.Wrap(err, "failed to parse right go.mod")
	}

	// Change the left hand module versions if the right hand versions
	// are greater than the left hand ones.
	for _, req := range templateMod.Require {
		v, err := semver.ParseTolerant(req.Mod.Version)
		if err != nil {
			continue
		}

		// If it already exists, skip it if it's newer or equal to the one we want
		if origVer, ok := originalModHM[req.Mod.Path]; ok && origVer.GTE(v) {
			continue
		}

		if err := origMod.AddRequire(req.Mod.Path, req.Mod.Version); err != nil {
			return "", errors.Wrapf(err, "failed to add/update dependency '%s'", req.Mod.Path)
		}
	}

	// Carry over replacements from the right hand go.mod
	for _, repl := range templateMod.Replace {
		// This isn't great performance, but I suspect nobody will have a large
		// enough amount of replaces that this will ever matter. If it does,
		// I'm sorry :(
		alreadyFound := false
		for _, origRepl := range origMod.Replace {
			// Check if we have a replace that matches
			if origRepl.New.Path == repl.New.Path &&
				origRepl.Old.Path == repl.Old.Path {
				alreadyFound = true
				break
			}
		}
		if alreadyFound {
			break
		}

		if err := origMod.AddReplace(repl.Old.Path, repl.Old.Version, repl.New.Path, repl.New.Version); err != nil {
			return "", errors.Wrapf(err, "failed to add replace: %v", repl)
		}
	}

	if err := origMod.AddGoStmt(templateMod.Go.Version); err != nil {
		return "", errors.Wrap(err, "failed to set go version")
	}

	newBytes, err := origMod.Format()
	if err != nil {
		return "", errors.Wrap(err, "failed to save generated go.mod")
	}
	return string(newBytes), nil
}
