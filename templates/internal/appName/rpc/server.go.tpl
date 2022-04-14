// Copyright {{ .currentYear }} Outreach Corporation. All Rights Reserved.

// Description: This file contains the gRPC server implementation for the {{ .appName }}
// API defined in api/{{ .underscoreAppName }}.proto. This implementation is used in the
// rpc.go when creating and exposing the gRPC server.

package {{ .underscoreAppName }} //nolint:revive // Why: This nolint is here just in case your project name contains any of [-_].

import (
	"context"
{{ if .manifest.Temporal }}
{{ if .manifest.Temporal.Client }}
	temporalclient "go.temporal.io/sdk/client"
	"github.com/getoutreach/services/pkg/temporal"
	"github.com/getoutreach/{{ .repo }}/internal/{{ .appName }}/workflows"
{{ end }}
{{ end }}
	"github.com/getoutreach/mint/pkg/authn"
)

// Server is the actual server implementation of the API.
//
// Note that tracing, logging and metrics are already handled for these
// methods.
type Server struct{
	// Place any handler state for your service here.
{{- if .manifest.Temporal }}
{{- if .manifest.Temporal.Client }}
	temporalc temporalclient.Client
{{- end }}
{{- end }}
}

// Define a `NewServer` function for your service here.
func NewServer(ctx context.Context, cfg *Config) (*Server, error) {
{{- if .manifest.Temporal }}
{{- if .manifest.Temporal.Client }}
        c, err := temporal.CreateClient(ctx, nil)
        if err != nil {
                return nil, errors.Wrap(err, "failed to init server")
        }

        return &Server{temporalc: c}, nil
{{- else }}
       return &Server{}, nil
{{- end }}
{{- else }}
       return &Server{}, nil
{{- end }}
}

// Place any GRPC handler functions for your service here.
func (s *Server) Ping(ctx context.Context, message string) (string, error) {
	// example authn check is shown here
	if email := authn.CurrentUserEmail(ctx); string(email) != "" {
		return "pong:" + message + " " + string(email), nil
	}
	return "pong:" + message, nil
}

func (s *Server) Pong(ctx context.Context, message string) (string, error) {
	// example authn check is shown here
	if email := authn.CurrentUserEmail(ctx); string(email) != "" {
		return "pong:" + message + " " + string(email), nil
	}
	return "ping:" + message, nil
}

// Close is a dummy method which will always return an error. It is neither
// called nor used on the server, but is required by the api.Service interface.
func (s *Server) Close(_ context.Context) error {
	return fmt.Errorf("closing the server is not allowed")
}

{{ if .manifest.Temporal }}
{{ if .manifest.Temporal.Client }}
// StartPingPongWorkflow implements the PingPongWorkflow temporal handler for the Server
// pointer receiver.
func (s *Server) StartPingPongWorkflow(ctx context.Context, message string) (string, error) {
        opts := temporalclient.StartWorkflowOptions{
                TaskQueue: workflows.TaskQueueName,
        }
        run, err := s.temporalc.ExecuteWorkflow(ctx, opts, workflows.PingPongWorkflow, message)
        if err != nil {
                return "", err
        }
        return fmt.Sprintf("Started worfklow ID: '%s'", run.GetID()), nil
}
{{ end }}
{{ end }}
