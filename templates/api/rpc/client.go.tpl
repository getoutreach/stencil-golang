// {{ stencil.ApplyTemplate "copyright" }} 

// Description: This file contains the gRPC client implementation for the
// {{ .Config.Name }} service.

package {{ stencil.ApplyTemplate "goPackageSafeName" }} //nolint:revive // Why: We allow [-_].

import (
	"context"

	"github.com/getoutreach/mint/pkg/authn"
	"github.com/getoutreach/services/pkg/grpcx"

	"{{ stencil.ApplyTemplate "appImportPath" }}/api"
)

// New returns a new grpc client for the {{ .Config.Name }} Service
//
// The client is concurrency safe and handles reconnecting.
// All calls automatically handle logging, tracing, metrics,
// service discovery, and authn.
func New(ctx context.Context) (api.Service, error) {
{{- range stencil.GetModuleHook "rpc.New" }}
{{ indent 2 . }}
{{- end }}
	return &client{
	  grpcConn: conn,
{{- range stencil.GetModuleHook "rpc.New.client" }}
{{ indent 2 . }}
{{- end }}
	  {{ title .Config.Name }}Client: api.New{{ title .Config.Name }}Client(conn),
	}, nil
}

// client is the type that actually implements the correct interface to serve as
// a gRPC client for the {{ .Config.Name }} service as per the protobuf files.
type client struct {
  grpcConn    *grpc.ClientConn
{{- range stencil.GetModuleHook "rpc.client" }}
{{ indent 2 . }}
{{- end }}
	api.{{ title .Config.Name }}Client
	// Place your client struct data here
}

// Close is necessary to avoid potential resource leaks
func (c client) Close(ctx context.Context) error {
	closers := []func() error{
{{- range stencil.GetModuleHook "rpc.Close.closers" }}
{{ indent 2 . }}
{{- end }}
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
	resp, err := c.{{ title .Config.Name }}Client.Ping(ctx, in)
	if err != nil {
		return "", err
	}
	return resp.Message, nil
}

func (c client) Pong(ctx context.Context, message string) (string, error) {
	in := &api.PongRequest{Message: message}
	resp, err := c.{{ title .Config.Name }}Client.Pong(ctx, in)
	if err != nil {
		return "", err
	}
	return resp.Message, nil
}

{{- range stencil.GetModuleHook "rpc.methods" }}
{{ indent 2 . }}
{{- end }}
