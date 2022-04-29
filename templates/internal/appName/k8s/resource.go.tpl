{{- $_ := stencil.ApplyTemplate "kubernetes.skipIfNot" }}
// {{ stencil.ApplyTemplate "copyright" }} 

// Description: This file defines the Resouce interface for controllers/webhooks
// Managed: true

// Package k8s holds definitions common to all controllers and webhooks in k8s
package k8s

import (
	"context"

	ctrl "sigs.k8s.io/controller-runtime"

	"github.com/getoutreach/gobox/pkg/log"

	///Block(imports)
{{ file.Block "imports" }}
	///EndBlock(imports)
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
	///Block(resourceMethods)
{{ file.Block "resourceMethods" }}
	///EndBlock(resourceMethods)
}
