{{- if not (has "grpc" (stencil.Arg "serviceActivities")) }}
{{ file.Skip "Not a gRPC service" }}
{{- end }}
{{- $_ := file.SetPath (printf "internal/%s/%s" .Config.Name (base file.Path)) }}
{{- $_ := file.Static }}
{{- $pkgName := stencil.ApplyTemplate "goPackageSafeName" }}
// go:build or_int
// +build or_int

// {{ stencil.ApplyTemplate "copyright" }}

package  {{ $pkgName }}_test

import (
	"context"
	"fmt"
	"net"
	"testing"

	client "github.com/getoutreach/{{ .Config.Name }}/api/{{ .Config.Name }}"
	server "github.com/getoutreach/{{ .Config.Name }}/internal/{{ .Config.Name }}"
	"github.com/getoutreach/{{ .Config.Name }}/internal/{{ $pkgName }}test"
	"github.com/getoutreach/gobox/pkg/events"
	"github.com/getoutreach/gobox/pkg/log"
	"github.com/getoutreach/tollmon/pkg/tollgate"
	orglife "github.com/getoutreach/orgservice/pkg/lifecycle"
)

func (suite) Test{{ title $pkgName }}RPC(t *testing.T) {
	// Initialize an instance of your server implementation here.
	instance := &server.Server{}
	s, err := server.StartServer(context.Background(), instance)
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

	{{ $pkgName }}test.Run{{ title $pkgName }}Tests(t, c)
}

func (suite) Test{{ title $pkgName }}Server(t *testing.T) {
	instance := &server.Server{}
	{{ $pkgName }}test.Run{{ title $pkgName }}Tests(t, instance)
}
