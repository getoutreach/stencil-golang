// Copyright {{ .currentYear }} Outreach Corporation. All Rights Reserved.

// Description: This file defines the gRPC server service interface for
// {{ .appName }}.

package api

import (
	"context"
)

// Service is the {{ .titleName }} server interface
//
// This interface is implemented by the server and the rpc client
type Service interface {
	// Close all connections and release resources.
	Close(ctx context.Context) error
	Ping(ctx context.Context, message string) (string, error)
	Pong(ctx context.Context, message string) (string, error)
{{ if .manifest.Temporal }}
{{ if .manifest.Temporal.Client }}

        StartPingPongWorkflow(ctx context.Context, message string) (string, error)
{{ end }}
{{ end }}
}
