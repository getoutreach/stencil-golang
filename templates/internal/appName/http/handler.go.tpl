// {{ stencil.ApplyTemplate "copyright" }} 

// Description: This file exposes the public HTTP service for {{ .Config.Name }}.

package {{ stencil.ApplyTemplate "goPackageSafeName" }} //nolint:revive // Why: We allow [-_].
import (
	"net/http"

	"github.com/getoutreach/httpx/pkg/handlers"
	"github.com/getoutreach/gobox/pkg/events"
	"github.com/getoutreach/gobox/pkg/log"
	"github.com/gorilla/mux"
)

// Handler returns the main http handler for this service
func Handler() http.Handler {
	svc := &service{}

	routes := mux.NewRouter()

	// Replace this with your routes
	routes.Handle("/ping", handlers.Endpoint("ping", svc.ping))
	routes.Handle("/pong", handlers.Endpoint("pong", svc.pong))

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
