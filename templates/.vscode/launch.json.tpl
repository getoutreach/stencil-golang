{
  // Use IntelliSense to learn about possible attributes.
  // Hover to view descriptions of existing attributes.
  // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Launch Debug Server",
      "type": "go",
      "request": "launch",
      "mode": "debug",
      "envFile": "${workspaceRoot}/.vscode/private.env",
      "go.testEnvFile": "${workspaceRoot}/.vscode/private.env",
      "program": "${workspaceRoot}/cmd/{{ .Config.Name }}/",
      "buildFlags": "-tags=or_dev"
    },
    {
      "name": "Attach to dev container",
      "type": "go",
      "debugAdapter": "dlv-dap",
      "request": "attach",
      "mode": "remote",
      ///Block(vscodeRemoteDebug)
{{- if file.Block "vscodeRemoteDebug" }}
{{ file.Block "vscodeRemoteDebug" }}
{{ else }}
      "host": "127.0.0.1",
      "port": 42097,
{{- end }}
    ///EndBlock(vscodeRemoteDebug)
      "substitutePath": [
        {
          "from": "${workspaceRoot}",
          "to": "/home/dev/app"
        },
        {
          "from": "${env:HOME}/.asdf/installs/golang/{{ stencil.ApplyTemplate "goVersion" }}/packages/pkg/mod",
          "to": "/tmp/cache/go/mod/"
        },
        {
          "from": "${env:HOME}/.asdf/installs/golang/{{ stencil.ApplyTemplate "goVersion" }}/go/src",
          "to": "/home/dev/.asdf/installs/golang/{{ stencil.ApplyTemplate "goVersion" }}/go/src"
        }
      ],
    },
    ///Block(vscodeLaunchConfigs)
{{ file.Block "vscodeLaunchConfigs" }}
    ///EndBlock(vscodeLaunchConfigs)
  ]
}
