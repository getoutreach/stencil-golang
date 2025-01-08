{
  // Please consider contributing back all added
  // settings to stencil!
  // <<Stencil::Block(settings)>>
{{ file.Block "settings" }}
  // <</Stencil::Block>>
  "go.lintTool": "golangci-lint",
  "go.lintFlags": [],
  "go.formatTool": "goimports",
  "go.useLanguageServer": true,
  "go.testEnvFile": "${workspaceFolder}/.vscode/private.env",
  "go.alternateTools": {
    "golangci-lint": "${workspaceFolder}/.bootstrap/shell/vscode/golang-linters.sh"
  },
  // This is disabled because it causes version mismatches between the
  // tools used/installed by asdf / stencil, and the ones updated by VSCode.
  // In particular, this is a problem with newer versions of golangci-lint
  // incompatible with older versions of Go.
  "go.toolsManagement.autoUpdate": false,
  "go.buildTags": "or_dev",
  "go.testTags": "or_test,or_int,or_e2e",
  "files.trimTrailingWhitespace": true,
  // This prevents 99% of issues with linters :)
  "editor.formatOnSave": true,
  "shellcheck.customArgs": [
    "-P",
    "SCRIPTDIR",
    "-x"
  ],
  "shellformat.path": "./.bootstrap/shell/shfmt.sh",
  "[dockerfile]": {
    "editor.defaultFormatter": "ms-azuretools.vscode-docker"
  },
  "[markdown]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
  },
  "[proto3]": {
    "editor.defaultFormatter": "zxh404.vscode-proto3"
  },
  "[yaml]": {
    "editor.defaultFormatter": "redhat.vscode-yaml"
  },
  "gopls": {
    "build.buildFlags": [
      "-tags=or_test,or_dev,or_e2e,or_int"
    ],
  },
  "[terraform]": {
    "editor.defaultFormatter": "hashicorp.terraform"
  },
  "protoc": {
    "options": ["--proto_path=${workspaceRoot}/api"]
  }
}
