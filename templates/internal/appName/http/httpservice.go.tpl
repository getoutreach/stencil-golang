// Copyright {{ .currentYear }} Outreach Corporation. All Rights Reserved.

// Description: This file exposes the private HTTP service for {{ .appName }}.
// Managed: true

package {{ .underscoreAppName }} //nolint:revive // Why: This nolint is here just in case your project name contains any of [-_].

import (
	"context"
	"fmt"
	"net/http"

	"github.com/getoutreach/gobox/pkg/events"
	"github.com/getoutreach/gobox/pkg/log"
	"github.com/getoutreach/httpx/pkg/handlers"


	// Place any extra imports for your service code here
	///Block(imports)
	{{- if .imports }}
{{ .imports }}
	{{- end }}
	///EndBlock(imports)
)

// HTTPService handles internal http requests
type HTTPService struct {
	handlers.Service
}

// Run is the entrypoint for the HTTPService serviceActivity.
func (s *HTTPService) Run(ctx context.Context, config *Config) error {
	// create a http handler (handlers.Service does metrics, health etc)
	///Block(privatehandler)
	{{- if .privatehandler }}
{{ .privatehandler }}
	{{- else }}
	s.App = http.NotFoundHandler()
	{{- end }}
	///EndBlock(privatehandler)
	return s.Service.Run(ctx, fmt.Sprintf("%s:%d", config.ListenHost, config.HTTPPort))
}

{{ if .http }}
// PublicHTTPService handles public http service calls
type PublicHTTPService struct {
	handlers.PublicService
}

// Run starts the HTTP service at the host/port specified in the config
func (s *PublicHTTPService) Run(ctx context.Context, config *Config) error {
	// set your public handler here.
	///Block(publichandler)
	{{- if .publichandler }}
{{ .publichandler }}
	{{- else }}
	s.App = Handler()
	{{- end }}
	///EndBlock(publichandler)
	return s.PublicService.Run(ctx, fmt.Sprintf("%s:%d", config.ListenHost, config.PublicHTTPPort))
}
{{ end }}
