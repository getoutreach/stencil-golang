// +build or_int

package  {{ .underscoreAppName -}}_test

import (
	"context"
	"fmt"
	"net"
	"testing"

	client "github.com/getoutreach/{{- .repo -}}/api/{{- .appName -}}"
	server "github.com/getoutreach/{{- .repo -}}/internal/{{- .appName -}}"
	"github.com/getoutreach/{{- .repo -}}/internal/{{- .appName -}}test"
	"github.com/getoutreach/gobox/pkg/events"
	"github.com/getoutreach/gobox/pkg/log"
	"github.com/getoutreach/tollmon/pkg/tollgate"
	orglife "github.com/getoutreach/orgservice/pkg/lifecycle"
)

func (suite) Test{{- .titleName -}}RPC(t *testing.T) {
	// Initialize an instance of your server implementation here.
	///Block(server)
        {{- if .server }}
{{ .server }}
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

	{{ .underscoreAppName -}}test.Run{{- .titleName -}}Tests(t, c)
}

func (suite) Test{{- .titleName -}}Server(t *testing.T) {
	///Block(serverTwo)
        {{- if .serverTwo }}
{{ .serverTwo }}
        {{- else }}
	instance := &server.Server{}
	{{- end }}
	///EndBlock(serverTwo)
	{{ .underscoreAppName -}}test.Run{{- .titleName -}}Tests(t, instance)
}
