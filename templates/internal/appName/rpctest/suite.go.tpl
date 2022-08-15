{{- if not (has "grpc" (stencil.Arg "serviceActivities")) }}
{{ file.Skip "Not a gRPC service" }}
{{- end }}
{{- $_ := file.SetPath (printf "internal/%stest/%s" .Config.Name (base file.Path)) }}
{{- $_ := file.Static }}
// +build or_int
// {{ stencil.ApplyTemplate "copyright" }}

// Package {{ .Config.Name }}test implements the test suite for the {{ .Config.Name }} service.
package {{ stencil.ApplyTemplate "goPackageSafeName" }}test //nolint:revive // Why: We allow [-_].


import (
	"context"
	"testing"

	"github.com/getoutreach/{{ .Config.Name }}/api"
	"github.com/getoutreach/gobox/pkg/shuffler"

	"gotest.tools/v3/assert"
)

// Run{{- stencil.ApplyTemplate "goPackageSafeName" -}}Tests runs a set of tests on the generic service
//
// Specific implementations are expected to be server implementations
// and rpc-based client implementations.
func Run{{- stencil.ApplyTemplate "goPackageSafeName" -}}Tests(t *testing.T, s api.Service) {
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
