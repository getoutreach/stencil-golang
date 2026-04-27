{
  "recommendations": [
    "DrBlury.protobuf-vsc",
    "editorconfig.editorconfig",
    "esbenp.prettier-vscode",
    "hashicorp.terraform",
    "mads-hartmann.bash-ide-vscode",
    "golang.go",
    "Grafana.vscode-jsonnet",
    "redhat.vscode-yaml",
    "ms-azuretools.vscode-docker",
    {{- if and (has "grpc" (stencil.Arg "serviceActivities")) (has "node" (stencil.Arg "grpcClients")) }}
    "laktak.hjson",
    {{- end }}

    {{- range (stencil.GetModuleHook "vscode/additional-extensions") }}
    {{ . }}
    {{- end }}

    // Please consider contributing back all recommended
    // extensions to stencil!
    // <<Stencil::Block(extensions)>>
{{ file.Block "extensions" }}
    // <</Stencil::Block>>
  ]
}
