// Please modify this to match the interface specified in {{ .appName }}.go
syntax = "proto3";

package {{ .repo }}.api;

option go_package = "github.com/getoutreach/{{ .repo }}/api";
option ruby_package = "{{ .titleName }}Client";

// Define your grpc service structures here
// PingRequest is the request for ping
message PingRequest {
  string message = 1;
}

// PingResponse is the response for echo.
message PingResponse {
  string message = 1;
}

// PongRequest is the request for ping
message PongRequest {
  string message = 1;
}

// PongResponse is the response for echo.
message PongResponse {
  string message = 1;
}

{{ if .manifest.Temporal }}
{{ if .manifest.Temporal.Client }}
message StartPingPongWorkflowRequest {
  string message = 1;
}

message StartPingPongWorkflowResponse {
  string result = 1;
}

{{ end }}
{{ end }}
// {{ .titleName }} is the {{ .appName }} service.
service {{ .titleName }} {
  rpc Ping(PingRequest) returns (PingResponse) {}
  rpc Pong(PongRequest) returns (PongResponse) {}
{{ if .manifest.Temporal }}
{{ if .manifest.Temporal.Client }}

  rpc StartPingPongWorkflow(StartPingPongWorkflowRequest) returns (StartPingPongWorkflowResponse) {}
{{ end }}
{{ end }}
}
