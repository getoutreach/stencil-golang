// Copyright {{ .currentYear }} Outreach Corporation. All Rights Reserved.

// Description: This file contains test for the gRPC client for {{ .appName }} service.

// +build or_test or_int

// Please edit this file to more accurately reflect the service.

package {{ .underscoreAppName }} //nolint:revive // Why: This nolint is here just in case your project name contains any of [-_].

import (
	"context"

	"github.com/getoutreach/mint/pkg/authn"
	"github.com/getoutreach/services/pkg/grpcx"

	"github.com/getoutreach/{{- .repo -}}/api"
)

// NewForTest returns a test grpc client for the {{ .appName }} Service
//
// This `ForTest` client does not include service discovery.
// It requires that the server address be explicitly specified.
func NewForTest(ctx context.Context, server string) (api.Service, error) {
	useAuthn := grpcx.WithAuthnHeaders(func (ctx context.Context) map[string][]string {
		if c := authn.FromContext(ctx); c != nil {
			return authn.ToHeaders(ctx, c)
		}
		return nil
	})

	conn, err := grpcx.NewClientConn(ctx, server, useAuthn)
	if err != nil {
		return nil, err
	}
	return &client{ grpcConn: conn, {{- .titleName -}}Client: api.New{{- .titleName -}}Client(conn)}, nil
}
