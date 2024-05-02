{
  "recommendations": [
    "editorconfig.editorconfig",
    "esbenp.prettier-vscode",
    "hashicorp.terraform",
    "golang.go",
    "Grafana.vscode-jsonnet",
    "timonwong.shellcheck",
    "zxh404.vscode-proto3",
    "redhat.vscode-yaml",
    "ms-azuretools.vscode-docker",
    "foxundermoon.shell-format",
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
