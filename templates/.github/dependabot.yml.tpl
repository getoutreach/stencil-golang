{{- $deps := stencil.ApplyTemplate "dependencies" | fromYaml }}
version: 2
updates:
  # Golang dependencies
  - package-ecosystem: "gomod"
    directory: "/"
    schedule:
      interval: "daily"
    # stencil-golang managed dependencies
    ignore:
{{- range $d := $deps.go }}
      - dependency-name: {{ $d.name }}
{{- end }}

  # Ignore semantic-release, this code is only executed in CI.
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "daily"
    ignore:
      - dependency-name: "*"

{{- if and (has "grpc" (stencil.Arg "serviceActivities")) (has "node" (stencil.Arg "grpcClients")) }}
  # Node client for gRPC services
  - package-ecosystem: "npm"
    directory: "/api/clients/node"
    schedule:
      interval: "daily"
    # stencil-golang managed dependencies
    ignore:
{{- range $d := (concat $deps.nodejs.dependencies $deps.nodejs.devDependencies) }}
      - dependency-name: {{ $d.name | quote }}
{{- end }}
{{- end }}

  ## <<Stencil::Block(dependabotPackageManagers)>>
{{ file.Block "dependabotPackageManagers" }}
  ## <</Stencil::Block>>
