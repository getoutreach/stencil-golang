// TODO(jaredallard): Make static.
package main

import (
	"testing"

	"github.com/getoutreach/stencil/pkg/stenciltest"
)

// Replace this with your own tests.
func TestRenderAFile(t *testing.T) {
	st := stenciltest.New(t, "your_file.ext.tpl", "helpers.tpl")
	st.Args(map[string]interface{}{
		"argument": true,
	})
	st.Run(false)
}
