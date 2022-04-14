// Copyright {{ .currentYear }} Outreach Corporation. All Rights Reserved.

// Description: This file contains the gRPC client implementation for the
// {{ .appName }} service.

package {{ .underscoreAppName }} //nolint:revive // Why: This nolint is here just in case your project name contains any of [-_].

import (
	"context"

	"github.com/getoutreach/mint/pkg/authn"
	"github.com/getoutreach/services/pkg/grpcx"

	"github.com/getoutreach/{{- .repo -}}/api"
)

// New returns a new grpc client for the {{ .appName }} Service
//
// The client is concurrency safe and handles reconnecting.
// All calls automatically handle logging, tracing, metrics,
// service discovery, and authn.
func New(ctx context.Context) (api.Service, error) {
	useDiscovery := grpcx.WithServiceDiscovery()

	authnConfig := authn.Config{
		Audience: "{{- .serviceID -}}",
		ForwardAccountsToken: true,
		MintDisabled: false,
	}
	authnClient, err := authn.NewClient(ctx, &authnConfig)
	if err != nil {
		 return nil, err
	}
	useAuthn := grpcx.WithAuthn(authnClient)
	conn, err := grpcx.NewClientConn(ctx, "{{- .appName -}}", useAuthn, useDiscovery)
	if err != nil {
		return nil, err
	}
	return &client{
	  grpcConn: conn,
	  authnClient: authnClient,
	  {{- .titleName -}}Client: api.New{{- .titleName -}}Client(conn),
	}, nil
}

// client is the type that actually implements the correct interface to serve as
// a gRPC client for the {{ .appName }} service as per the protobuf files.
type client struct {
  grpcConn    *grpc.ClientConn
	authnClient *authn.Client
	api.{{- .titleName -}}Client
	// Place your client struct data here
}

// Close is necessary to avoid potential resource leaks
func (c client) Close(ctx context.Context) error {
	closers := []func() error{
		func() error {
		  // close authn client
			if c.authnClient != nil {
				return c.authnClient.Close(ctx)
			}
			return nil
		},
		func() error {
		  // close grpc connection
			if c.grpcConn != nil {
			  // Calling close is necessary to avoid potential resource leaks
        // See: https://pkg.go.dev/google.golang.org/grpc#ClientConn.NewStream
				return c.grpcConn.Close()
			}
			return nil
		},
	}
	errors := make([]error, 0)
	for _, fn := range closers {
		if err := fn(); err != nil {
			errors = append(errors, err)
		}
	}

	if len(errors) != 0 {
		return fmt.Errorf("failed to close client: %v", errors)
	}
	return nil
}

// Place any client handler functions for your service here
func (c client) Ping(ctx context.Context, message string) (string, error) {
	in := &api.PingRequest{Message: message}
	resp, err := c.{{- .titleName -}}Client.Ping(ctx, in)
	if err != nil {
		return "", err
	}
	return resp.Message, nil
}

func (c client) Pong(ctx context.Context, message string) (string, error) {
	in := &api.PongRequest{Message: message}
	resp, err := c.{{- .titleName -}}Client.Pong(ctx, in)
	if err != nil {
		return "", err
	}
	return resp.Message, nil
}
{{ if .manifest.Temporal }}
{{ if .manifest.Temporal.Client }}

func (c client) StartPingPongWorkflow(ctx context.Context, message string) (string, error) {
        in := &api.StartPingPongWorkflowRequest{Message: message}
        resp, err := c.{{- .titleName -}}Client.StartPingPongWorkflow(ctx, in)
        if err != nil {
                return "", err
        }
        return resp.Result, nil
}
{{ end }}
{{ end }}
