{{- if not (has "grpc" (stencil.Arg "serviceActivities")) }}
{{- file.Skip "Not a gRPC service" }}
{{- end }}
{{- $_ := file.SetPath (printf "api/%s.proto" .Config.Name) }}
{{- $_ := file.Static }}
// {{ stencil.ApplyTemplate "copyright" }}
// Please modify this to match the interface specified in {{ .Config.Name }}.go
syntax = "proto3";

package {{ stencil.ApplyTemplate "goPackageSafeName" }}.api;

option go_package = "{{ stencil.ApplyTemplate "appImportPath" }}/api";
option ruby_package = "{{ regexReplaceAllLiteral "\\W+" .Config.Name " " | title | replace " " "" }}Client";

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

{{- /* Service names may have hyphens in them, but Golang structs and Protobuf
Services may NOT have hyphens in their name. To keep generated code valid,
convert the service name 'example-service' into 'ExampleService' for
compatibility. */ -}}
// {{ regexReplaceAllLiteral "\\W+" .Config.Name " " | title | replace " " "" }} is the {{ .Config.Name }} service.
service {{ regexReplaceAllLiteral "\\W+" .Config.Name " " | title | replace " " "" }} {
  rpc Ping(PingRequest) returns (PingResponse) {}
  rpc Pong(PongRequest) returns (PongResponse) {}
{{- range stencil.GetModuleHook "api.proto.service" }}
{{- . | indent 2}}
{{- end }}
}
