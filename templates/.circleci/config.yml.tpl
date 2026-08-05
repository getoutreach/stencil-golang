{{ file.Skip "Virtual file for CircleCI config via stencil-circleci" }}

{{- define "gRPCNodeJSClientTestWorkflowJob" }}
{{- $executorName := "" }}
{{- if contains "amazonaws.com" .Runtime.Box.Docker.ImagePullRegistry }}
{{- $executorName = "testbed-docker-aws" }}
{{- else }}
{{- $executorName = "testbed-docker" }}
{{- end }}
shared/test_node_client:
  context:
    {{- with .Runtime.Box.CI.CircleCI.Contexts }}
    {{- if .AWS }}
    # AWS Authentication Context
    - {{ .AWS }}
    {{- end }}
    {{- if .Github }}
    # Github Authentication Context
    - {{ .Github }}
    {{- end }}
    {{- if .Docker }}
    # Docker Authentication Context
    - {{ .Docker }}
    {{- end }}
    {{- if .ExtraContexts }}
    # Extra Contexts from box config
    {{- end }}
    {{- range .ExtraContexts }}
    - {{ . }}
    {{- end }}
    {{- end }}
  {{- if not (stencil.Arg "oss") }}
  executor_name: {{ $executorName }}
  {{- end }}
  steps: []
{{- end }}

{{ define "releaseNodeJSParam" }}
node_client: true
{{- end }}

{{ define "releaseNodeJSRequires" }}
- shared/test_node_client
{{- end }}

{{- if and (or (not (stencil.Arg "service")) (has "grpc" (stencil.Arg "serviceActivities"))) (has "node" (stencil.Arg "grpcClients")) }}
{{- stencil.AddToModuleHook "github.com/getoutreach/stencil-circleci" "workflows.release.jobs" (list (fromYaml (stencil.ApplyTemplate "gRPCNodeJSClientTestWorkflowJob"))) }}
{{- stencil.AddToModuleHook "github.com/getoutreach/stencil-circleci" "workflows.release.release.params" (list (stencil.ApplyTemplate "releaseNodeJSParam")) }}
{{- stencil.AddToModuleHook "github.com/getoutreach/stencil-circleci" "workflows.release.release.requires" (fromYaml (stencil.ApplyTemplate "releaseNodeJSRequires")) }}
{{- end }}
