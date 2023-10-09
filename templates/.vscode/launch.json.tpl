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
      // <<Stencil::Block(vscodeRemoteDebug)>>
{{- if file.Block "vscodeRemoteDebug" }}
{{ file.Block "vscodeRemoteDebug" }}
{{- else }}
      "host": "127.0.0.1",
      "port": 42097,
{{- end }}
      // <</Stencil::Block>>
      {{- $goVersion := stencil.ApplyTemplate "goVersion" }}
      // Paths to replace when running the debugger. "from" is the host
      // path and "to" is the path in the devspace.
      "substitutePath": [
        {
          // Maps the workspace root (the repository directory) to the path that
          // is compiled into the built binary. Note: This is not impacted by trimpath
          // because devbase currently uses dlv to compile the source code.
          // See: https://github.com/getoutreach/devbase/blob/main/shell/debug.sh#L72
          "from": "${workspaceRoot}",
          "to": "/home/dev/app"
        },
        // Maps the go module cache on the host to the persistent volume used by devspaces.
        // These should be the respective values of `go env GOMODCACHE`.
        {
          "from": "${env:HOME}/.asdf/installs/golang/{{ $goVersion }}/packages/pkg/mod",
          "to": "/home/dev/.asdf/installs/golang/{{ $goVersion }}/packages/pkg/mod"
        },
        {
          // Maps the standard library location on the host to the location in the devspace.
          // This enables debugging standard library code.
          "from": "${env:HOME}/.asdf/installs/golang/{{ $goVersion }}/go/src",
          "to": "/home/dev/.asdf/installs/golang/{{ $goVersion }}/go/src"
        }
      ],
    },
    {
      "name": "Attach to dev container (in binary mode)",
      "type": "go",
      "debugAdapter": "dlv-dap",
      "request": "attach",
      "mode": "remote",
      // <<Stencil::Block(vscodeRemoteDebugDevspaceBinary)>>
{{- if file.Block "vscodeRemoteDebugDevspaceBinary" }}
{{ file.Block "vscodeRemoteDebugDevspaceBinary" }}
{{- else }}
      "host": "127.0.0.1",
      "port": 42097,
{{- end }}
      // <</Stencil::Block>>
      {{- $goVersion := stencil.ApplyTemplate "goVersion" }}
    },
    // <<Stencil::Block(vscodeLaunchConfigs)>>
{{ file.Block "vscodeLaunchConfigs" }}
    // <</Stencil::Block>>
  ]
}
