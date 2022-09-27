{{- if not (has "grpc" (stencil.Arg "serviceActivities")) }}
{{- file.Skip "Not a gRPC service" }}
{{- end }}
{{- $_ := file.SetPath (printf "api/%s/%s" .Config.Name (base file.Path)) }}
{{- $_ := file.Static }}
{{- $pkgName := stencil.ApplyTemplate "goPackageSafeName" }}
// {{ stencil.ApplyTemplate "copyright" }}

// Description: This file contains the gRPC client implementation for the
// {{ .Config.Name }} service.

package {{ stencil.ApplyTemplate "goPackageSafeName" }} //nolint:revive // Why: We allow [-_].

import (
	"context"

	"github.com/getoutreach/services/pkg/grpcx"
	"github.com/getoutreach/{{ .Config.Name }}/api"

	{{- $additionalImports := stencil.GetModuleHook "api/rpc/client.additionalImports" }}
	{{- if $additionalImports }}
	// imports added by modules
		{{- range $additionalImports }}
	{{ . | quote }}
		{{- end }}
	// end imports added by modules
	{{- end }}
)

// New returns a new grpc client for the {{ .Config.Name }} Service
//
// The client is concurrency safe and handles reconnecting.
// All calls automatically handle logging, tracing, metrics,
// service discovery, and authn.
func New(ctx context.Context) (api.Service, error) {	
	{{- $initializeClient := stencil.GetModuleHook "api/rpc/client.initializeClient" }}
	{{- if $initializeClient }}
	// Inserted by modules
	{{- range $initializeClient }}
	{{ . }}
	{{- end }}
	// End Inserted by modules
	{{- end }}

	clientOpts := []grpcx.ClientConnOption{
		grpcx.WithServiceDiscovery(),

		{{- $clientOpts := stencil.GetModuleHook "api/rpc/client.clientOpts" }}
		{{- if $clientOpts }}
		// Inserted by modules
		{{- range $clientOpts }}
		{{ . }},
		{{- end }}
		// End Inserted by modules
		{{- end }}
	}

	conn, err := grpcx.NewClientConn(ctx, "{{ .Config.Name }}", clientOpts...)
	if err != nil {
		return nil, err
	}
	return &client{
		closers: []func(ctx context.Context) error{
			{{- $closers := stencil.GetModuleHook "api/rpc/client.closers" }}
			{{- if $closers }}
			// Closers Inserted by modules
			{{- range $closers }}
			{{ . }},
			{{- end }}
			// End closers inserted by modules
			{{- end }}
			func(_ context.Context) error { return conn.Close() },
		},
	  {{ title $pkgName }}Client: api.New{{ title $pkgName }}Client(conn),
	}, nil
}

// client is the type that actually implements the correct interface to serve as
// a gRPC client for the rms service as per the protobuf files.
type client struct {
	closers []func(ctx context.Context) error
	api.{{ title $pkgName }}Client
	// Place your client struct data here
}

// Close is necessary to avoid potential resource leaks
func (c client) Close(ctx context.Context) error {
	errors := make([]error, 0)
	for _, fn := range c.closers {
		if err := fn(ctx); err != nil {
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
	resp, err := c.{{ title $pkgName }}Client.Ping(ctx, in)
	if err != nil {
		return "", err
	}
	return resp.Message, nil
}

func (c client) Pong(ctx context.Context, message string) (string, error) {
	in := &api.PongRequest{Message: message}
	resp, err := c.{{ title $pkgName }}Client.Pong(ctx, in)
	if err != nil {
		return "", err
	}
	return resp.Message, nil
}
