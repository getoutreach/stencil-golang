// Copyright 2023 Outreach Corporation. All Rights Reserved.

// Description: This file holds the ShutdownFromSignalError and Signal structs/enums for use by the ShutdownError
package shutdown

import "fmt"

// Signal is an enum for which signal type caused the shutdown
type Signal int

// String satisfies the Stringer interface to convert enum types to strings
func (s Signal) String() string {
	switch s {
	case SignalInterrupt:
		return "Interrupt"
	case SignalTerminated:
		return "Terminated"
	case SignalHangUp:
		return "HangUp"
	}
	return fmt.Sprintf("Error: %d", s)
}

// List of signals for thue ShutdownFromSignalError
const (
	// SignalInterrupt is SIGINT
	SignalInterrupt Signal = 1
	// SignalTerminated is SIGTERM
	SignalTerminated Signal = 2
	// SignalHangUp is SIGHUP
	SignalHangUp Signal = 3
)

// ShutdownFromSignalError is an error struct used by the Shutdown activity to indicate which signal caused the shutdown.
type ShutdownFromSignalError struct {
	Signal Signal
}

// Error satisfies the error interface
func (s ShutdownFromSignalError) Error() string {
	return fmt.Sprintf("shutting down due to interrupt: %v", s.Signal)
}
