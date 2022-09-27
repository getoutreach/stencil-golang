package gomaxprocs

import (
	"context"
	"fmt"

	"github.com/getoutreach/gobox/pkg/async"
	"github.com/getoutreach/gobox/pkg/events"
	"github.com/getoutreach/gobox/pkg/log"
	"go.uber.org/automaxprocs/maxprocs"
)

// _ ensures that ServiceActivity implements the async.Runner interface.
var _ async.Runner = (*ServiceActivity)(nil)

// _ ensures that ServiceActivity implements the async.Closer interface.
var _ async.Closer = (*ServiceActivity)(nil)

// ServiceActivity implements the async.Runner & Closer interface for setting
// GOMAXPROCS properly in a containerized environment.
type ServiceActivity struct {
	undo func()
}

// New creates a new gomaxprocs service activity
func New() *ServiceActivity {
	return &ServiceActivity{}
}

// Run runs the gomaxprocs service activity
func (s *ServiceActivity) Run(ctx context.Context) error {
	var err error
	s.undo, err = maxprocs.Set(maxprocs.Logger(func(m string, args ...interface{}) {
		message := fmt.Sprintf(m, args...)
		log.Info(ctx, "maxprocs.Set", log.F{"message": message})
	}))
	if err != nil {
		log.Error(ctx, "maxprocs.Set", events.NewErrorInfo(err))
	}

	<-ctx.Done()
	return nil
}

// Close closes the gomaxprocs service activity
func (s *ServiceActivity) Close(_ context.Context) error {
	if s.undo != nil {
		s.undo()
	}
	return nil
}
