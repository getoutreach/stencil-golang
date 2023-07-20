// Copyright 2023 Outreach Corporation. All Rights Reserved.

// Description: Implements the automemlimit package.

// Package automemlimit implements a service activity that
// sets the GOMEMLIMIT[1] to be a percentage of the total cgroup
// memory limit. This is useful for containerized environments
// where the GC will not be able to detect the total memory
// available to the process and thus will not be able to
// properly determine when an out of memory condition is
// about to occur in relation to freeing memory.
//
// This is controllable with environment variables provided
// by the automemlimit package[2].
//
// [1]: https://weaviate.io/blog/gomemlimit-a-game-changer-for-high-memory-applications
// [2]: https://github.com/KimMachineGun/automemlimit
package automemlimit

import (
	"context"

	"github.com/KimMachineGun/automemlimit/memlimit"
	"github.com/getoutreach/gobox/pkg/async"
)

// _ ensures that ServiceActivity implements the async.Runner interface.
var _ async.Runner = (*ServiceActivity)(nil)

// _ ensures that ServiceActivity implements the async.Closer interface.
var _ async.Closer = (*ServiceActivity)(nil)

// ServiceActivity implements the async.Runner & Closer interface for setting
// GOMEMLIMIT properly in a containerized environment.
type ServiceActivity struct{}

// New creates a new automemlimit service activity
func New() *ServiceActivity {
	return &ServiceActivity{}
}

// Run runs the automemlimit service activity
func (s *ServiceActivity) Run(ctx context.Context) error {
	memlimit.SetGoMemLimitWithEnv()
	<-ctx.Done()
	return nil
}

// Close closes the automemlimit service activity. This is a noop.
func (s *ServiceActivity) Close(_ context.Context) error {
	return nil
}
