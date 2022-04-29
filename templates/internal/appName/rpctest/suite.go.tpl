{{- if not (has "grpc" (stencil.Arg "type")) }}
{{ file.Skip "Not a gRPC service" }}
{{- end }}
{{- $_ := file.SetPath (printf "internal/%stest/%s" .Config.Name (base file.Path)) }}
// {{ stencil.ApplyTemplate "copyright" }} 

// go:build or_int

// Package {{ stencil.ApplyTemplate "goPackageSafeName" }}test implements the test suite for the {{ .Config.Name }} service.
package {{ stencil.ApplyTemplate "goPackageSafeName" }}test //nolint:revive // Why: We allow [-_].


import (
	"context"
	"testing"

	"{{ stencil.ApplyTemplate "appImportPath" }}/api"
	"github.com/getoutreach/mint/pkg/authn"
	"github.com/getoutreach/mint/pkg/authn/authntest"
	"github.com/getoutreach/gobox/pkg/shuffler"

	"gotest.tools/v3/assert"
)

// Run{{ title .Config.Name }}Tests runs a set of tests on the generic service
//
// Specific implementations are expected to be server implementations
// and rpc-based client implementations.
func Run{{ title .Config.Name }}Tests(t *testing.T, s api.Service) {
	shuffler.Run(t, suite{s})
}

type suite struct {
	api.Service
}

// Update this with your specific methods
func (s suite) TestPing(t *testing.T) {
	ctx := context.Background()
	message, err := s.Service.Ping(ctx, "hello")
	assert.NilError(t, err)
	assert.Equal(t, message, "pong:hello")
}

func (s suite) TestPong(t *testing.T) {
	ctx := context.Background()
	message, err := s.Service.Pong(ctx, "hello")
	assert.NilError(t, err)
	assert.Equal(t, message, "ping:hello")
}

func (s suite) TestAuthenticated(t *testing.T) {
	ctx := context.Background()
	defer authntest.UseSharedKey("testing")()

	ctx, err := authntest.NewContextForEmail(ctx, "someone@somewhere")
	assert.NilError(t, err)

	message, err := s.Ping(ctx, "hello")
	assert.NilError(t, err)
	assert.Equal(t, message,"pong:hello someone@somewhere")
}
