{{- if not (stencil.Arg "service") }}
{{ file.Skip "Not a service" }}
{{- end }}
{{- $_ := file.SetPath (printf "internal/%s/%s" .Config.Name (base file.Path)) }}
// {{ stencil.ApplyTemplate "copyright" }}

// Description: This file exposes the private HTTP service for {{ .Config.Name }}.
// Managed: true

package {{ stencil.ApplyTemplate "goPackageSafeName" }} //nolint:revive // Why: We allow [-_].

import (
	"context"
	"fmt"
	"net/http"

	"github.com/getoutreach/gobox/pkg/events"
	"github.com/getoutreach/gobox/pkg/log"
	"github.com/getoutreach/httpx/pkg/handlers"


	// Place any extra imports for your service code here
	///Block(imports)
{{ file.Block "imports" }}
	///EndBlock(imports)
)

// HTTPService handles internal http requests, suchs as metrics, health
// and readiness checks. This is required for ALL services to have.
type HTTPService struct {
	handlers.Service

	cfg *Config
}

// NewHTTPService creates a new HTTPService service activity.
func NewHTTPService(cfg *Config) *HTTPService {
	return &HTTPService{cfg: cfg}
}

// Run is the entrypoint for the HTTPService serviceActivity.
func (s *HTTPService) Run(ctx context.Context) error {
	// create a http handler (handlers.Service does metrics, health etc)
	///Block(privatehandler)
{{ file.Block "privatehandler" | default "s.App = http.NotFoundHandler()" }}
	///EndBlock(privatehandler)
	return s.Service.Run(ctx, fmt.Sprintf("%s:%d", s.cfg.ListenHost, s.cfg.HTTPPort))
}

{{- if has "http" (stencil.Arg "serviceActivities") }}
// PublicHTTPService handles public http service calls
type PublicHTTPService struct {
	handlers.PublicService

	cfg *Config
}

// NewPublicHTTPService creates a new PublicHTTPService service activity.
func NewPublicHTTPService(cfg *Config) *PublicHTTPService {
	return &PublicHTTPService{cfg: cfg}
}

// Run starts the HTTP service at the host/port specified in the config
func (s *PublicHTTPService) Run(ctx context.Context) error {
	// set your public handler here.
	///Block(publichandler)
{{ file.Block "publichandler" | default "s.App = Handler()" }}
	///EndBlock(publichandler)
	return s.PublicService.Run(ctx, fmt.Sprintf("%s:%d", s.cfg.ListenHost, s.cfg.PublicHTTPPort))
}
{{- end }}
