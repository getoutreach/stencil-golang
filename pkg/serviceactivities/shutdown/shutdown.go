// Copyright 2023 Outreach Corporation. All Rights Reserved.

// Description: See package comment.

// Package shut down is a service activity that handles graceful shutdowns.
package shutdown

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"github.com/getoutreach/gobox/pkg/async"
	"github.com/getoutreach/gobox/pkg/orerr"
)

// _ ensures that ServiceActivity implements the async.Runner interface.
var _ async.Runner = (*ServiceActivity)(nil)

// _ ensures that ServiceActivity implements the async.Closer interface.
var _ async.Closer = (*ServiceActivity)(nil)

// ServiceActivity implements the async.Runner & Closer interface for handling graceful
// shutdowns.
type ServiceActivity struct {
	done chan struct{}
}

// New creates a new shutdown service activity that listens for interrupt signals
// and handles gracefully shutting down the entire application.
func New() *ServiceActivity {
	return &ServiceActivity{
		done: make(chan struct{}),
	}
}

// Run runs the shutdown service activity
func (s *ServiceActivity) Run(ctx context.Context) error {
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

// Close closes the shutdown service activity
func (s *ServiceActivity) Close(_ context.Context) error {
	close(s.done)
	return nil
}
