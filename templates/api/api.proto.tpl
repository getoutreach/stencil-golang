{{- $_ := file.Static }}
// {{ stencil.ApplyTemplate "copyright" }} 
// Please modify this to match the interface specified in {{ .appName }}.go
syntax = "proto3";

package {{ .repo }}.api;

option go_package = "github.com/{{ .Runtime.Box.Org }}/{{ .Config.Name }}/api";
option ruby_package = "{{ .Config.Name | title }}Client";

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

{{- range stencil.GetModuleHook "api.proto.message" }}
{{- . | indent 2}}
{{- end }}

// {{ .Config.Name | title }} is the {{ .Config.Name }} service.
service {{ .Config.Name | title }} {
  rpc Ping(PingRequest) returns (PingResponse) {}
  rpc Pong(PongRequest) returns (PongResponse) {}
{{- range stencil.GetModuleHook "api.proto.service" }}
{{- . | indent 2}}
{{- end }}
}
