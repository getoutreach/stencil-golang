{{- if not (has "grpc" (stencil.Arg "type")) }}
{{ file.Skip "Not a gRPC service" }}
{{- end }}
{{- $_ := file.SetPath (printf "internal/%s/%s" .Config.Name (base file.Path)) }}
// {{ stencil.ApplyTemplate "copyright" }} 

// go:build or_int

package {{ stencil.ApplyTemplate "goPackageSafeName" }}_test //nolint:revive // Why: We allow [-_].

import (
	"context"
	"fmt"
	"net"
	"testing"

	client "{{ stencil.ApplyTemplate "appImportPath" }}/api/{{ .Config.Name }}"
	server "{{ stencil.ApplyTemplate "appImportPath" }}/internal/{{ .Config.Name }}"
	"{{ stencil.ApplyTemplate "appImportPath" }}/internal/{{ .Config.Name }}test"
	"github.com/getoutreach/gobox/pkg/events"
	"github.com/getoutreach/gobox/pkg/log"
	"github.com/getoutreach/tollmon/pkg/tollgate"
	orglife "github.com/getoutreach/orgservice/pkg/lifecycle"
)

func (suite) Test{{ title .Config.Name }}RPC(t *testing.T) {
	// Initialize an instance of your server implementation here.
	///Block(server)
	{{- if file.Block "server" }}
{{ file.Block "server" }}
	{{- else }}
	instance := &server.Server{}
	{{- end }}
	///EndBlock(server)
	s, err := server.StartServer(context.Background(), instance, 
		tollgate.New("test", tollgate.WithMonitoringMode(true)), orglife.New(server.OrgHooks()))
	if err != nil {
		t.Fatalf("failed: %v\n", err)
	}
	t.Cleanup(func() { s.GracefulStop() })

	l, err := net.Listen("tcp", "127.0.0.1:")
	if err != nil {
		t.Fatalf("failed: %v", err)
	}
	t.Cleanup(func() { l.Close() })

	go func() {
		s.Serve(l)
	}()

	c, err := client.NewForTest(context.Background(), l.Addr().String())
	if err != nil {
		t.Fatalf("could not dial client: %v\n", err)
	}

	{{ stencil.ApplyTemplate "goPackageSafeName" }}test.Run{{ title .Config.Name }}Tests(t, c)
}

func (suite) Test{{ title .Config.Name }}Server(t *testing.T) {
	///Block(serverTwo)
	{{- if file.Block "serverTwo" }}
{{ file.Block "serverTwo" }}
	{{- else }}
	instance := &server.Server{}
	{{- end }}
	///EndBlock(serverTwo)
	{{ stencil.ApplyTemplate "goPackageSafeName" }}test.Run{{ title .Config.Name }}Tests(t, instance)
}
