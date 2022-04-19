// {{ stencil.ApplyTemplate "copyright" }} 

// go:build or_int

// This example was created by {{ .Runtime.Generator }} and will not be updated by {{ .Runtime.Generator }} again.
//
// The contents of this file are meant to exist as part of the project
// and provide documentation as an example of how to use the service's API.
//
// This file should be kept up-to-date with your service and compile cleanly.
//
// This example will be accessible via engdocs.outreach.cloud, so
// please make sure the example illustrates how to use the API.
package {{ stencil.ApplyTemplate "goPackageSafeName" }}_test //nolint:revive // Why: We allow [-_].


import (
	"context"
	"fmt"
	"net"

	client "{{ stencil.ApplyTemplate "appImportPath" }}/api/{{ .Config.Name }}"
	server "{{ stencil.ApplyTemplate "appImportPath" }}/internal/{{ .Config.Name }}"
	"github.com/getoutreach/gobox/pkg/events"
	"github.com/getoutreach/gobox/pkg/log"
	"github.com/getoutreach/gobox/pkg/trace"
	"github.com/getoutreach/gobox/pkg/secrets/secretstest"	
	"github.com/getoutreach/tollmon/pkg/tollgate"
	orglife "github.com/getoutreach/orgservice/pkg/lifecycle"
)

func Example() {
	// Initialize an instance of your server implementation here.
	instance := &server.Server{}
	s, err := server.StartServer(context.Background(), instance, 
		tollgate.New("test", tollgate.WithMonitoringMode(true)), orglife.New(server.OrgHooks()))
	if err != nil {
		log.Error(context.Background(), "failed", events.NewErrorInfo(err))
		return
	}
	defer s.GracefulStop()

	l, err := net.Listen("tcp", "127.0.0.1:")
	if err != nil {
		log.Error(context.Background(), "failed", events.NewErrorInfo(err))
		return
	}
	defer l.Close()

	go func() {
		s.Serve(l)
	}()

	// We use a `ForTest` client so we can talk to the test service we
	// started above.  A more typical client would use `client.New` and
	// omit the second argument, relying on automatic service discovery.
	c, err := client.NewForTest(context.Background(), l.Addr().String())
	if err != nil {
		log.Error(context.Background(), "could not dial client", events.NewErrorInfo(err))
		return
	}

	// Place any GRPC handler functions for your service here.
	message, err := c.Ping(context.Background(), "hello")
	fmt.Println("got", message, err)

	message, err = c.Pong(context.Background(), "hello")
	fmt.Println("got", message, err)

	//Output:
	// got pong:hello <nil>
	// got ping:hello <nil>
}
