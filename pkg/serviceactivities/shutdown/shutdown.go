// Copyright 2023 Outreach Corporation. All Rights Reserved.

// Description: See package comment.

// Package shut down is a service activity that handles graceful shutdowns.
package shutdown

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"github.com/getoutreach/gobox/pkg/async"
	"github.com/getoutreach/gobox/pkg/events"
	"github.com/getoutreach/gobox/pkg/log"
	"github.com/getoutreach/gobox/pkg/orerr"
)

// FromSignalError is an error struct used by the Shutdown activity to indicate which signal caused the shutdown.
type FromSignalError struct {
	Signal os.Signal
}

// Error satisfies the error interface
func (s FromSignalError) Error() string {
	return fmt.Sprintf("shutting down due to interrupt: %v", s.Signal)
}

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
	// listen for interrupt, terminated, and hangup signals and gracefully shutdown server
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM, syscall.SIGHUP)

	select {
	case sig := <-c:
		// Allow interrupt signals to be caught again in worse-case scenario
		// situations when the service hangs during a graceful shutdown.
		signal.Reset(os.Interrupt, syscall.SIGTERM, syscall.SIGHUP)
		return orerr.ShutdownError{Err: FromSignalError{Signal: sig}}
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

// HandleShutdownConditions encapsulates the shutdown logging logic for services into a simple function, and returns
// a new error code to set, if any
func HandleShutdownConditions(ctx context.Context, err error) *int {
	if err != nil {
		var fsErr FromSignalError
		if is := errors.As(err, &fsErr); is && (fsErr.Signal == syscall.SIGTERM) {
			log.Info(ctx, "service gracefully shutdown due to termination", events.NewErrorInfo(err))
			exitCode := 0
			return &exitCode
		}

		// Anything other than a SIGTERM to the ShutdownActivity is "unexpected"
		log.Error(ctx, "service down unexpectedly", events.NewErrorInfo(err))
		return nil
	}

	log.Info(ctx, "service gracefully shutdown without error")
	exitCode := 0
	return &exitCode
}
