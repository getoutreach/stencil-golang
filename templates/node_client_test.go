// Copyright 2026 Outreach Corporation. All Rights Reserved.

// Description: Template tests specific to the Node gRPC client.

package main_test

import (
	"testing"
)

func TestNodeClientIndexHasExportsBlock(t *testing.T) {
	assertTemplateSnapshot(t, "api/clients/node/src/index.ts.tpl", map[string]any{
		"service":     true,
		"grpcClients": []any{"node"},
	})
}
