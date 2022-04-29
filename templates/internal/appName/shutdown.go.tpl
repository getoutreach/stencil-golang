{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
{{- $_ := file.SetPath (printf "internal/%s/%s" .Config.Name (base file.Path)) }}
// {{ stencil.ApplyTemplate "copyright" }} 

// Description: This file implements a service that handles graceful shutdowns.
// Managed: true

package {{ stencil.ApplyTemplate "goPackageSafeName" }} //nolint:revive // Why: We allow [-_].

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"github.com/getoutreach/gobox/pkg/orerr"
)

// ShutdownService implements the ServiceActivity interface for handling graceful
// shutdowns.
type ShutdownService struct {
	done chan struct{}
}

func NewShutdownService() *ShutdownService {
	return &ShutdownService{
		done: make(chan struct{}),
	}
}

// Run helps implement the ServiceActivity for its pointer receiver, ShutdownService.
// This function listens for interrupt signals and handles gracefully shutting down
// the entire application.
func (s *ShutdownService) Run(ctx context.Context, _ *Config) error {
	// listen for interrupts and gracefully shutdown server
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM, syscall.SIGHUP)

	select {
	case out := <-c:
        // Allow interrupt signals to be caught again in worse-case scenario
        // situations when the service hangs during a graceful shutdown.
        signal.Reset(os.Interrupt, syscall.SIGTERM, syscall.SIGHUP)

		err := fmt.Errorf("shutting down due to interrupt: %v", out)
		return orerr.ShutdownError{Err: err}
	case <-ctx.Done():
		return ctx.Err()
	case <-s.done:
		return nil
	}
}

func (s *ShutdownService) Close(_ context.Context) error {
	close(s.done)
	return nil
}
