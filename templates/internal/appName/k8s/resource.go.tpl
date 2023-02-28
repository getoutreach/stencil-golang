// {{ stencil.ApplyTemplate "copyright" }}
{{- $_ := file.SetPath (printf "internal/k8s/%s" (base file.Path)) }}
{{- $_ := stencil.ApplyTemplate "kubernetes.skipIfNot" }}

// Description: This file defines the Resource interface for controllers/webhooks
// Managed: true

// Package k8s holds definitions common to all controllers and webhooks in k8s
package k8s

import (
	"context"

	ctrl "sigs.k8s.io/controller-runtime"

	"github.com/getoutreach/gobox/pkg/log"

	// <<Stencil::Block(imports)>>
{{ file.Block "imports" }}
	// <</Stencil::Block>>
)

// Resource provides methods common to all webhooks and controllers.
type Resource interface {
	// Marshaler makes sure each Resource provides MarshalLog implementation.
	log.Marshaler

	// Kind returns the kind of k8s CRD or native object served by this resource.
	Kind() string

	// Version returns the version of the current resource.
	Version() string

	// Setup registers the webhook or the controller with the k8s manager.
	Setup(mgr ctrl.Manager) error

	// Close cleans up the resource upon exit.
	Close(ctx context.Context) error

	// Extra shared methods here.
	// <<Stencil::Block(resourceMethods)>>
{{ file.Block "resourceMethods" }}
	// <</Stencil::Block>>
}
