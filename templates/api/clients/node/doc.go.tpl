{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "node" -}}
// {{ stencil.ApplyTemplate "copyright" }} 

// Description: This file just serves as a doc for the client package.

// Package client is only used to generate the node gRPC client.
package client
