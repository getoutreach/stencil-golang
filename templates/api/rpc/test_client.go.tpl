// {{ stencil.ApplyTemplate "copyright" }} 

// Description: This file contains test for the gRPC client for {{ .Config.Name }} service.

// go:build or_test or_int

// Please edit this file to more accurately reflect the service.

package {{ stencil.ApplyTemplate "goPackageSafeName" }} //nolint:revive // Why: We allow [-_].

import (
	"context"

	"github.com/getoutreach/mint/pkg/authn"
	"github.com/getoutreach/services/pkg/grpcx"

	"{{ stencil.ApplyTemplate "appImportPath" }}/api"
)

// NewForTest returns a test grpc client for the {{ .Config.Name }} Service
//
// This `ForTest` client does not include service discovery.
// It requires that the server address be explicitly specified.
func NewForTest(ctx context.Context, server string) (api.Service, error) {
	/// !!!! TODO: Need to split this out w/ authn, but need to model this
	/// outside of bootstrap first.
{{- stencil.GetModuleHook "rpc.NewForTest" | indent 2}}

	conn, err := grpcx.NewClientConn(ctx, server, <TODO>)
	if err != nil {
		return nil, err
	}
	return &client{ grpcConn: conn, {{ title .Config.Name }}Client: api.New{{ title .Config.Name }}Client(conn)}, nil
}
