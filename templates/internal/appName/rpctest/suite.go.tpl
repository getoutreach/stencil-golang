// +build or_int

// Package {{ .appName}}test implements the test suite for the {{ .appName }} service.
package {{ .underscoreAppName -}}test

import (
	"context"
	"testing"

	"github.com/getoutreach/{{- .repo -}}/api"
	"github.com/getoutreach/mint/pkg/authn"
	"github.com/getoutreach/mint/pkg/authn/authntest"
	"github.com/getoutreach/gobox/pkg/shuffler"

	"gotest.tools/v3/assert"
)

// Run{{- .titleName -}}Tests runs a set of tests on the generic service
//
// Specific implementations are expected to be server implementations
// and rpc-based client implementations.
func Run{{- .titleName -}}Tests(t *testing.T, s api.Service) {
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
