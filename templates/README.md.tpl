{{ file.Skip "Virtual file for README.md module hooks from stencil-base" }}

{{- define "grpcServiceActivity" }}
### via gRPC

[grpcui](https://github.com/fullstorydev/grpcui) can be useful for talking to {{ .Config.Name }} locally. To run it:

```bash
make grpcui
```
{{- end }}

{{- define "httpServiceActivity" }}
### via HTTP

There are two different HTTP servers running by default on stencil services, a public (external) and a private
(internal) server. By default, the port for the public server is `8080`, and the port for the private server is `8000`.
These are subject to change, and if they are changed, those changes should be reflected in
`deployments/{{ .Config.Name }}/{{ .Config.Name }}.config.jsonnet`.

If the service is running locally either through running `make devserver` or running the binary directly, you can
interact with these servers over `localhost` or `127.0.0.1` using the appropriate port.

If the service is running in kubernetes you'll either have to launch an alpine pod into the namespace and interact with
the HTTP servers using cURL (make sure to `apk add curl` in the alpine container) or you can port-forward to get access
to them on your local network:

```bash
devenv kubectl -n {{ .Config.Name }}--bento1a port-forward service/{{ .Config.Name }} <port>
```

Where port is either the port for the public or private HTTP server.
{{- end }}

{{- if has "grpc" (stencil.Arg "serviceActivities") }}
{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "serviceActivityDescriptions" (list (stencil.ApplyTemplate "grpcServiceActivity")) }}
{{- end }}
{{- if has "http" (stencil.Arg "serviceActivities") }}
{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "serviceActivityDescriptions" (list (stencil.ApplyTemplate "httpServiceActivity")) }}
{{- end }}
