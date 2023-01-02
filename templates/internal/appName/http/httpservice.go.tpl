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

  {{- $additionalImports := stencil.GetModuleHook "internal/http/additionalImports" }}
	{{- if $additionalImports }}
	// imports added by modules
		{{- range $additionalImports }}
	{{ . | quote }}
		{{- end }}
	// end imports added by modules
	{{- end }}

	// Place any extra imports for your service code here
	// <<Stencil::Block(imports)>>
{{ file.Block "imports" }}
	// <</Stencil::Block>>
)

// PrivateHTTPDependencies is used to inject dependencies into the HTTPService service
// activity.
type PrivateHTTPDependencies struct{
    // <<Stencil::Block(privateHTTPDependencies)>>
{{ file.Block "privateHTTPDependencies" }}
	  // <</Stencil::Block>>

    {{- $privateHTTPDependencyInjection := stencil.GetModuleHook "internal/http/privateHTTPDependencyInjection" }}
    {{- if $privateHTTPDependencyInjection }}
    // dependencies injected by modules
    {{- range $privateHTTPDependencyInjection }}
    {{ . }}
    {{- end }}
    // end dependencies injected by modules
    {{- end }}
}

// HTTPService handles internal http requests, suchs as metrics, health
// and readiness checks. This is required for ALL services to have.
type HTTPService struct {
	handlers.Service

	cfg *Config
  deps *PublicHTTPDependencies
}

// NewHTTPService creates a new HTTPService service activity.
func NewHTTPService(cfg *Config, deps *PrivateHTTPDependencies) *HTTPService {
	  return &HTTPService{
        cfg: cfg,
        deps: deps,
    }
}

// Run is the entrypoint for the HTTPService serviceActivity.
func (s *HTTPService) Run(ctx context.Context) error {
	// create a http handler (handlers.Service does metrics, health etc)
	// <<Stencil::Block(privatehandler)>>
{{ file.Block "privatehandler" | default "s.App = http.NotFoundHandler()" }}
	// <</Stencil::Block>>
	return s.Service.Run(ctx, fmt.Sprintf("%s:%d", s.cfg.ListenHost, s.cfg.HTTPPort))
}

{{- if has "http" (stencil.Arg "serviceActivities") }}
// PublicHTTPDependencies is used to inject dependencies into the PublicHTTPService
// service activity.
type PublicHTTPDependencies struct{
    // <<Stencil::Block(publicHTTPDependencies)>>
{{ file.Block "publicHTTPDependencies" }}
	  // <</Stencil::Block>>

    {{- $publicHTTPDependencyInjection := stencil.GetModuleHook "internal/http/publicHTTPDependencyInjection" }}
    {{- if $publicHTTPDependencyInjection }}
    // dependencies injected by modules
    {{- range $publicHTTPDependencyInjection }}
    {{ . }}
    {{- end }}
    // end dependencies injected by modules
    {{- end }}
}

// PublicHTTPService handles public http service calls
type PublicHTTPService struct {
	  handlers.PublicService

	  cfg *Config
    deps *PublicHTTPDependencies
}

// NewPublicHTTPService creates a new PublicHTTPService service activity.
func NewPublicHTTPService(cfg *Config, deps *PublicHTTPDependencies) *PublicHTTPService {
	  return &PublicHTTPService{
        cfg: cfg,
        deps: deps,
    }
}

// Run starts the HTTP service at the host/port specified in the config
func (s *PublicHTTPService) Run(ctx context.Context) error {
	// set your public handler here.
	// <<Stencil::Block(publichandler)>>
{{ file.Block "publichandler" | default "s.App = Handler()" }}
	// <</Stencil::Block>>

    {{- $publicHTTPPreServerRun := stencil.GetModuleHook "internal/http/publicHTTPPreServerRun" }}
    {{- if $publicHTTPPreServerRun }}
    // code inserted by modules
    {{- range $publicHTTPPreServerRun }}
    {{ . }}
    {{- end }}
    // end code inserted by modules
    {{- end }}

	return s.PublicService.Run(ctx, fmt.Sprintf("%s:%d", s.cfg.ListenHost, s.cfg.PublicHTTPPort))
}
{{- end }}
