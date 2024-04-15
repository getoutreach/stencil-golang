// Copyright 2024 Outreach Corporation. All Rights Reserved.

// Description: Template tests specific to the Ruby gRPC client.

package main_test

import (
	"testing"

	"github.com/getoutreach/stencil/pkg/stenciltest"
)

func TestIncludeRubyToolVersionsIfRubyGRPCClient(t *testing.T) {
	st := stenciltest.New(t, "testdata/tool-versions-ruby/.tool-versions.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"grpcClients": []interface{}{"ruby"},
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestIncludeRubyToolVersionsIfRubyGRPCClientLibrary(t *testing.T) {
	// Need to use testdata because stenciltest cannot test file.Skip
	st := stenciltest.New(t, "testdata/tool-versions-ruby/.tool-versions.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{
		"grpcClients":       []interface{}{"ruby"},
		"service":           false,
		"serviceActivities": []interface{}{},
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestDontIncludeRubyToolVersionsIfNotRubyGRPCClient(t *testing.T) {
	st := stenciltest.New(t, "testdata/tool-versions-ruby/.tool-versions.tpl", libraryTmpls...)
	st.Args(map[string]interface{}{})
	st.Run(stenciltest.RegenerateSnapshots())
}
