{{- if not (has "http" (stencil.Arg "serviceActivities")) }}
{{ file.Skip "Not a HTTP service" }}
{{- end }}
{{- $_ := file.SetPath (printf "internal/%s/%s" .Config.Name (base file.Path)) }}
{{- $_ := file.Static }}
// {{ stencil.ApplyTemplate "copyright" }}

// Description: This file exposes the public HTTP service for {{ .Config.Name }}.
{{- $extraComments := (stencil.GetModuleHook "http/extraComments") }}
{{- range $extraComments }}
{{- .}}
{{- end }}

package {{ stencil.ApplyTemplate "goPackageSafeName" }} //nolint:revive // Why: We allow [-_].
import (
	"net/http"
{{- $extraStandardImports := (stencil.GetModuleHook "http/extraStandardImports") }}
{{- range $extraStandardImports }}
{{- .}}
{{- end }}

	"github.com/getoutreach/httpx/pkg/handlers"
	"github.com/getoutreach/gobox/pkg/events"
	"github.com/getoutreach/gobox/pkg/log"
	"github.com/gorilla/mux"
	{{- $additionalImports := stencil.GetModuleHook "http/additionalImports" }}
  {{- range $additionalImports }}
  {{ . | quote }}
  {{- end }}

)

// Handler returns the main http handler for this service
func Handler() http.Handler {
	svc := &service{}

	routes := mux.NewRouter()

	// Replace this with your routes
	routes.Handle("/ping", handlers.Endpoint("ping", svc.ping))
	routes.Handle("/pong", handlers.Endpoint("pong", svc.pong))
{{- $extraRoutes := (stencil.GetModuleHook "http/extraRoutes") }}
{{- range $extraRoutes }}
{{- .}}
{{- end }}
	return routes
}

// service is a type that contains receiver functions that serve as handlers
// for individual HTTP routes.
type service struct{}

// Place any http handler functions for your service here
func (s service) ping(w http.ResponseWriter, r *http.Request) {
	if _, err := w.Write([]byte("pong")); err != nil {
		log.Debug(r.Context(), "io write error", events.NewErrorInfo(err))
	}
}

func (s service) pong(w http.ResponseWriter, r *http.Request) {
	if _, err := w.Write([]byte("ping")); err != nil {
		log.Debug(r.Context(), "io write error", events.NewErrorInfo(err))
	}
}

{{- $extraFuncs := (stencil.GetModuleHook "http/extraFuncs") }}
{{- range $extraFuncs }}
{{- .}}
{{- end }}
