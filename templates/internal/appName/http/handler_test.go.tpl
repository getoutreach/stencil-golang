{{- if not (has "http" (stencil.Arg "serviceActivities")) }}
{{ file.Skip "Not a HTTP service" }}
{{- end }}
{{- $_ := file.Static }}
{{- $_ := file.SetPath (printf "internal/%s/%s" .Config.Name (base file.Path)) }}
// {{ stencil.ApplyTemplate "copyright" }} 

package {{ stencil.ApplyTemplate "goPackageSafeName" }}_test //nolint:revive // Why: We allow [-_].

import (
	"fmt"
	"io"
	"net/http/httptest"

	"{{ stencil.ApplyTemplate "appImportPath" }}/internal/{{ .Config.Name }}"
	"github.com/getoutreach/gobox/pkg/log"
	"github.com/getoutreach/gobox/pkg/shuffler"

	"github.com/getoutreach/services/pkg/find/findtest"
)

func (suite) TestHandlerPong(t *testing.T) {
	state := testSetup()
	defer state.Close()

	// state.Client() refers to state.Server.Client()
	// state.URL refers to state.Server.URL
	resp, err := state.Client().Get(state.URL + "/pong")
	if err != nil {
		t.Fatal("Unexpected error", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil || string(body) != "ping" {
		t.Error("Unexpected error", err, string(body))
	}
}

func (suite) TestHandlerMissingRoute(t *testing.T) {
	state := testSetup()
	defer state.Close()

	resp, err := state.Client().Get(state.URL + "/something")
	if err != nil {
		t.Fatal("Unexpected error", err)
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusNotFound {
		t.Fatal("Unexpected response status", resp.StatusCode)
	}
}

// Use the following pattern to write examples to illustrate
// how to use a package.
func ExampleHandler_ping() {
	state := testSetup()
	defer state.Close()

	srv := httptest.NewServer({{ stencil.ApplyTemplate "goPackageSafeName" }}.Handler())
	defer srv.Close()

	resp, err := srv.Client().Get(srv.URL + "/ping")
	if err != nil {
		fmt.Println("Unexpected error", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Println("Unexpected error", err)
	}

	fmt.Println(string(body))

	// Output: pong
}

// this is a contrived example of test state setup and
// tear down
type testState struct {
	oldOutput io.Writer
	*httptest.Server
}

func (t testState) Close() {
	log.SetOutput(t.oldOutput)
	t.Server.Close()
}

func testSetup() testState {
	state := testState{log.Output(), httptest.NewServer({{ stencil.ApplyTemplate "goPackageSafeName" }}.Handler())}
	log.SetOutput(io.Discard)
	return state
}
