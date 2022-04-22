{{- if not (has "grpc" (stencil.Arg "type")) }}
{{ file.Skip "Not a gRPC service" }}
{{- end }}
{{- $_ := file.SetPath (printf "internal/%s/%s" .Config.Name (base file.Path)) }}
// {{ stencil.ApplyTemplate "copyright" }} 

// Description: This file contains the gRPC server passthrough implementation for the
// {{ .Config.Name }} API defined in api/{{ .Config.Name }}.proto. The concrete implementation
// exists in the server.go file in this same directory.
// Managed: true

package {{ stencil.ApplyTemplate "goPackageSafeName" }} //nolint:revive // Why: We allow [-_].

import (
	"context"
	"fmt"
	"net"

	"github.com/getoutreach/gobox/pkg/app"
	"github.com/getoutreach/gobox/pkg/events"
	"github.com/getoutreach/gobox/pkg/log"
	"github.com/getoutreach/gobox/pkg/trace"
	"{{ stencil.ApplyTemplate "appImportPath" }}/api"
	"github.com/getoutreach/mint/pkg/authn"
	"github.com/getoutreach/orgservice/pkg/lifecycle"
	"github.com/getoutreach/services/pkg/grpcx"
	"github.com/getoutreach/tollmon/pkg/tollgate"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
	// Place any extra imports for your handler code here
	///Block(imports)
{{ file.Block "imports" }}
	///EndBlock(imports)
)

// GRPCService is the concrete implementation of the serviceActivity interface
// which defines methods to start and stop a service. In this case the service
// being implemented is a gRPC server.
type GRPCService struct {
	Tollgate *tollgate.Tollgate
	OrgService *lifecycle.OrgService
}

// Run starts a gRPC server.
//
// Run returns on context cancellation, on a call to Close, or on failure.
// WHY: If you extend this at all (which you will), you end up hitting funlen lint issues.
// nolint: funlen // Why: This function is long for extensibility reasons since it is generated by bootstrap.
func (s *GRPCService) Run(ctx context.Context, cfg *Config) error {
    lc := &net.ListenConfig{}
    listAddy := fmt.Sprintf("%s:%d", cfg.ListenHost, cfg.GRPCPort)
    lis, err := lc.Listen(ctx, "tcp", listAddy)
    if err != nil {
        log.Error(ctx, "failed to listen", events.NewErrorInfo(err))
        return err
    }
    defer lis.Close()

    // Initialize your server instance here.
    ///Block(server)
	{{- if file.Block "server" }}
{{ file.Block "server" }}
	{{- else }}
	server, err := NewServer(ctx, cfg)
    if err != nil {
        log.Error(ctx, "failed to start server", events.NewErrorInfo(err))
        return err
    }
	{{- end }}
    ///EndBlock(server)

    srv, err := StartServer(ctx, server, s.Tollgate, s.OrgService)
	if err != nil {
        log.Error(ctx, "failed to start server", events.NewErrorInfo(err))
        return err
    }
    defer srv.Stop()

    go func() {
        <- ctx.Done()
        srv.GracefulStop()
    }()

    // Note: .Serve() blocks
    log.Info(ctx, "Serving GRPC Service on "+listAddy)
    if err2 := srv.Serve(lis); err2 != nil {
        log.Error(ctx, "unexpected grpc Serve error", events.NewErrorInfo(err2))
        return err2
    }

    return nil
}

func (s *GRPCService) Close(ctx context.Context) error {
    return nil
}

// StartServer starts a RPC server with the provided implementation.
//
// The server should be stopped with server.GracefulStop()
func StartServer(ctx context.Context, service api.Service, t *tollgate.Tollgate, o *lifecycle.OrgService) (*grpc.Server, error) {
	opts := []grpcx.ServerOption{
		t.WithUnaryServerInterceptorx(),
	}

	///Block(grpcServerOptions)
	{{- if file.Block "grpcServerOptions" }}
{{ file.Block "grpcServerOptions" }}
	{{- else }}
	withAuthn := grpcx.WithAuthnContext(func (ctx context.Context, headers map[string][]string, method string) context.Context {
		if c := authn.FromHeaders(ctx, headers); c != nil {
			trace.AddInfo(ctx, c)
			return authn.ToContext(ctx, c)
		}
		return ctx
	})
	opts = append(opts, withAuthn)
	{{- end }}
	///EndBlock(grpcServerOptions)

	s, err := grpcx.NewServer(ctx, opts...)
	if err != nil {
		return nil, err
	}

	// Register tollgate RPCs for rate-limiting
	t.RegisterRPCs(s)

	// Register org lifecycle hooks
	o.RegisterRPCs(s)

	// Register service
	api.Register{{ title .Config.Name }}Server(s, rpcserver{service})

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
///Block(handlers)
{{- if file.Block "handlers" }}
{{ file.Block "handlers" }}
{{- else }}
func (s rpcserver) Ping(ctx context.Context, req *api.PingRequest) (*api.PingResponse, error) {
	message, err := s.Service.Ping(ctx, req.Message)
	if err != nil {
		return nil, err
	}
	return &api.PingResponse{Message: message}, nil
}

func (s rpcserver) Pong(ctx context.Context, req *api.PongRequest) (*api.PongResponse, error) {
	message, err := s.Service.Pong(ctx, req.Message)
	if err != nil {
		return nil, err
	}
	return &api.PongResponse{Message: message}, nil
}
{{- end }}
///EndBlock(handlers)
