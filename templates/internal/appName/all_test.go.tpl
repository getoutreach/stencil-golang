{{- $_ := file.SetPath (printf "internal/%s/%s" .Config.Name (base file.Path)) }}
// {{ stencil.ApplyTemplate "copyright" }} 

package {{ stencil.ApplyTemplate "goPackageSafeName" }}_test //nolint:revive // Why: We allow [-_].


import (
	"testing"

	"github.com/getoutreach/gobox/pkg/shuffler"	
)

func TestAll(t *testing.T) {
     shuffler.Run(t, suite{})
}

type suite struct {}
