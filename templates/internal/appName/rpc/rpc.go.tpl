{{- if not (has "grpc" (stencil.Arg "serviceActivities")) }}
{{ file.Skip "Not a gRPC service" }}
{{- end }}
{{- $_ := file.SetPath (printf "internal/%s/%s" .Config.Name (base file.Path)) }}
{{- $pkgName := stencil.ApplyTemplate "goPackageSafeName" }}
// {{ stencil.ApplyTemplate "copyright" }}

// Description: This file contains the gRPC server passthrough implementation for the
// {{ .Config.Name }} API defined in api/{{ .Config.Name }}.proto. The concrete implementation
// exists in the server.go file in this same directory.
// Managed: true
{{- $extraComments := (stencil.GetModuleHook "internal/rpc/extraComments") }}
{{- range $extraComments }}
{{- .}}
{{- end }}

package {{ $pkgName }} //nolint:revive,doculint // Why: We allow [-_].

import (
	"context"
	"fmt"
	"net"
{{- $extraStandardImports := (stencil.GetModuleHook "internal/rpc/extraStandardImports") }}
{{- range $extraStandardImports }}
{{- .}}
{{- end }}

	"github.com/getoutreach/gobox/pkg/events"
	"github.com/getoutreach/gobox/pkg/log"
	"github.com/getoutreach/gobox/pkg/trace"
	"github.com/getoutreach/{{ .Config.Name }}/api"
	"github.com/getoutreach/services/pkg/grpcx"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	{{- $additionalImports := stencil.GetModuleHook "internal/rpc/additionalImports" }}
	{{- if $additionalImports }}
	// imports added by modules
		{{- range $additionalImports }}
	{{ . | quote }}
		{{- end }}
	// end imports added by modules
	{{- end }}

	// <<Stencil::Block(imports)>>
{{ file.Block "imports" }}
	// <</Stencil::Block>>
)

// GRPCDependencies is used to inject dependencies into the GRPCService service
// activity. Great examples of integrations to be placed into here would be a database
// connection or perhaps a redis client that the service activity needs to use.
type GRPCDependencies struct{
    // <<Stencil::Block(GRPCDependencies)>>
{{ file.Block "GRPCDependencies" }}
	  // <</Stencil::Block>>

    {{- $gRPCDependencyInjection := stencil.GetModuleHook "internal/rpc/gRPCDependencyInjection" }}
    {{- if $gRPCDependencyInjection }}
    // dependencies injected by modules
    {{- range $gRPCDependencyInjection }}
    {{ . }}
    {{- end }}
    // end dependencies injected by modules
    {{- end }}
}

// GRPCService is the concrete implementation of the serviceActivity interface
// which defines methods to start and stop a service. In this case the service
// being implemented is a gRPC server.
type GRPCService struct {
	cfg *Config
	deps *GRPCDependencies
}

// NewGRPCService creates a new GRPCService instance.
func NewGRPCService(cfg *Config, deps *GRPCDependencies) *GRPCService {
	return &GRPCService{
    cfg: cfg,
    deps: deps,
  }
}

// Servers holds all the server implementation instances.
type Servers struct {
  DefaultServer api.Service
  // Add your additional RPC servers here
  // <<Stencil::Block(servers)>>
{{ file.Block "servers" }}
  // <</Stencil::Block>>
}

// Run starts a gRPC server.
//
//nolint:funlen // Why: This function is long for extensibility reasons since it is generated by stencil.
func (gs *GRPCService) Run(ctx context.Context) error {
		lc := &net.ListenConfig{}
		listAddr := fmt.Sprintf("%s:%d", gs.cfg.ListenHost, gs.cfg.GRPCPort)
		lis, err := lc.Listen(ctx, "tcp", listAddr)
		if err != nil {
				log.Error(ctx, "failed to listen", events.NewErrorInfo(err))
				return err
		}
		defer lis.Close()

    var servers = &Servers{}
		var opts []grpcx.ServerOption
		// Initialize your server instance here.
		//
		// <<Stencil::Block(server)>>
	{{- if file.Block "server" }}
{{ file.Block "server" }}
	{{- else }}
		server, err := NewServer(ctx, gs.cfg)
		if err != nil {
				log.Error(ctx, "failed to create new server", events.NewErrorInfo(err))
				return err
		}
	{{- end }}
		// <</Stencil::Block>>
    servers.DefaultServer = server

		srv, err := gs.StartServers(ctx, servers, opts...)
		if err != nil {
				log.Error(ctx, "failed to start server", events.NewErrorInfo(err))
				return err
		}
		defer srv.Stop()

		// Shutdown the server when the context is canceled
		go func() {
				<-ctx.Done()
				srv.GracefulStop()
		}()

		// Note: .Serve() blocks
		log.Info(ctx, "Serving GRPC Service on "+listAddr)
		if err := srv.Serve(lis); err != nil {
			log.Error(ctx, "unexpected grpc Serve error", events.NewErrorInfo(err))
			return err
		}

		return nil
}

// Close closes the gRPC server.
func (gs *GRPCService) Close(ctx context.Context) error {
	return nil
}

// StartServers starts a RPC server with the provided implementation.
func (gs *GRPCService) StartServers(ctx context.Context, servers *Servers, opts... grpcx.ServerOption) (*grpc.Server, error) {
	{{- $grpcServerOptionInit := stencil.GetModuleHook "internal/rpc/grpcServerOptionInit" }}
	{{- if $grpcServerOptionInit }}
	// gRPC server option initialization injected by modules
		{{- range $grpcServerOptionInit }}
	{{ . }}

		{{- end }}
	// end gRPC server option initialization injected by modules

	{{- end }}
  {{- $grpcServerOptions := stencil.GetModuleHook "internal/rpc/grpcServerOptions" }}
  {{- if $grpcServerOptions }}
	opts = append([]grpcx.ServerOption{
		// gRPC server options injected by modules
			{{- range $grpcServerOptions }}
		{{ . }},
			{{- end }}
		// end gRPC server options injected by modules
	}, opts...)
  {{- end }}
  {{- if or $grpcServerOptionInit $grpcServerOptions }}

  {{- end }}
	// <<Stencil::Block(grpcServerOptions)>>
{{ file.Block "grpcServerOptions" }}
	// <</Stencil::Block>>

	s, err := grpcx.NewServer(ctx, opts...)
	if err != nil {
		return nil, err
	}

	{{- $additionalGRPCRPCS := stencil.GetModuleHook "internal/rpc/additionalGRPCRPCS" }}
	{{- if $additionalGRPCRPCS }}
	// gRPC RPCs injected by modules
		{{- range $additionalGRPCRPCS }}
	{{ . }}
		{{- end }}
	// end gRPC RPCs injected by modules
	{{- end }}

	// Register default server, title function won't work well when use underscore, so we make it dash first
	api.Register{{ stencil.ApplyTemplate "goTitleCaseName" }}Server(s, rpcserver{servers.DefaultServer})

	// Register your additional RPC servers here
	// <<Stencil::Block(registrations)>>
{{ file.Block "registrations" }}
	// <</Stencil::Block>>

	// Register reflection
	reflection.Register(s)

	return s, nil
}

// rpcserver is a shim that converts the generic Service interface
// into the grpc generated interface from the protobuf
type rpcserver struct {
	api.Service
}

// Place any GRPC handler functions for your service here
//
// <<Stencil::Block(handlers)>>
{{- if file.Block "handlers" }}
{{ file.Block "handlers" }}
{{- else }}

// Ping is a simple ping/pong handler.
func (s rpcserver) Ping(ctx context.Context, req *api.PingRequest) (*api.PingResponse, error) {
	message, err := s.Service.Ping(ctx, req.Message)
	if err != nil {
		return nil, err
	}
	return &api.PingResponse{Message: message}, nil
}

// Pong is a simple RPC that returns a message.
func (s rpcserver) Pong(ctx context.Context, req *api.PongRequest) (*api.PongResponse, error) {
	message, err := s.Service.Pong(ctx, req.Message)
	if err != nil {
		return nil, err
	}
	return &api.PongResponse{Message: message}, nil
}

{{- $additionalDefaultHandlers := stencil.GetModuleHook "internal/rpc/additionalDefaultHandlers" }}
{{- range $additionalDefaultHandlers }}
{{ . }}

{{- end }}
{{- end }}
// <</Stencil::Block>>
