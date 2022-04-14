// Code managed by {{ .tool }}, DO NOT MODIFY
// Please update to match your service definition.

package {{ .underscoreAppName }}_test

import (
	"testing"

	"github.com/getoutreach/gobox/pkg/shuffler"	
)

func TestAll(t *testing.T) {
     shuffler.Run(t, suite{})
}

type suite struct {}
