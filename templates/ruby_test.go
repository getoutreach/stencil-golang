// Copyright 2024 Outreach Corporation. All Rights Reserved.

// Description: Template tests specific to the Ruby gRPC client.

package main_test

import (
	"testing"
)

func TestIncludeRubyToolVersionsIfRubyGRPCClient(t *testing.T) {
	assertTemplateSnapshot(t, "testdata/tool-versions-ruby/.tool-versions.tpl", map[string]any{
		"grpcClients": []interface{}{"ruby"},
	})
}

func TestIncludeRubyToolVersionsIfRubyGRPCClientLibrary(t *testing.T) {
	// Need to use testdata because stenciltest cannot test file.Skip
	assertTemplateSnapshot(t, "testdata/tool-versions-ruby/.tool-versions.tpl", map[string]any{
		"grpcClients":       []interface{}{"ruby"},
		"service":           false,
		"serviceActivities": []interface{}{},
	})
}

func TestDontIncludeRubyToolVersionsIfNotRubyGRPCClient(t *testing.T) {
	assertTemplateSnapshot(t, "testdata/tool-versions-ruby/.tool-versions.tpl", map[string]any{})
}

func TestRubyClientHasPreServiceRequiresBlock(t *testing.T) {
	assertTemplateSnapshot(t, "api/clients/ruby/lib/client/client.rb.tpl", map[string]any{
		"service":     true,
		"grpcClients": []interface{}{"ruby"},
	})
}
