// {{ stencil.ApplyTemplate "copyright" }} 

// Package api is a helper package which defines the ping API
//
// This package is not meant to be used directly.  Clients should use
//
// github.com/getoutreach/{{ .Config.Name }}/api/{{ .Config.Name }}
// which implements a cleaner interface.
package api

// The following line(s) generate code using protobuf (e.g. {{ .Config.Name }}.pb.go)
//
//go:generate ../scripts/shell-wrapper.sh protoc.sh
