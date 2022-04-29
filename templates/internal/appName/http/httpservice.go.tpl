{{- if not (has "http" (stencil.Arg "type")) }}
{{ file.Skip "Not a HTTP service" }}
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
}

// Run is the entrypoint for the HTTPService serviceActivity.
func (s *HTTPService) Run(ctx context.Context, config *Config) error {
	// create a http handler (handlers.Service does metrics, health etc)
	///Block(privatehandler)
	{{- if file.Block "privatehandler" }}
{{ file.Block "privatehandler"  }}
	{{- else }}
	s.App = http.NotFoundHandler()
	{{- end }}
	///EndBlock(privatehandler)
	return s.Service.Run(ctx, fmt.Sprintf("%s:%d", config.ListenHost, config.HTTPPort))
}

{{ if has "http" (stencil.Arg "type") }}
// PublicHTTPService handles public http service calls
type PublicHTTPService struct {
	handlers.PublicService
}

// Run starts the HTTP service at the host/port specified in the config
func (s *PublicHTTPService) Run(ctx context.Context, config *Config) error {
	// set your public handler here.
	///Block(publichandler)
	{{- if file.Block "publichandler" }}
{{ file.Block "publichandler" }}
	{{- else }}
	s.App = Handler()
	{{- end }}
	///EndBlock(publichandler)
	return s.PublicService.Run(ctx, fmt.Sprintf("%s:%d", config.ListenHost, config.PublicHTTPPort))
}
{{ end }}
