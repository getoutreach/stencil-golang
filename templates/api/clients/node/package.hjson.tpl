{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "node" -}}
{
  // This file is not automatically turned into package.json
  // In order to do so, run: `make gogenerate` in the root
  // of this repository.

  "name": "@getoutreach/{{ .Config.Name }}-client",
  "version": "0.0.1",
  "description": "{{ .Config.Name }} client implementation",
  "main": "dist/index.js",
  "repository": "https://github.com/getoutreach/{{ .Config.Name }}",
  "files": [
    // <<Stencil::Block(nodeDistFiles)>>
{{ file.Block "nodeDistFiles" }}
    // <</Stencil::Block>>
    "dist"
  ],
  "license": "UNLICENSED",
  "dependencies": {
    // <<Stencil::Block(nodeDependencies)>>
{{ file.Block "nodeDependencies" }}
    // <</Stencil::Block>>
	{{- range $d := (stencil.ApplyTemplate "dependencies" | fromYaml).nodejs.dependencies }}
	  "{{ $d.name }}": "{{ $d.version }}",
	{{- end }}
  },
  "devDependencies": {
    // <<Stencil::Block(nodeDevDependencies)>>
{{ file.Block "nodeDevDependencies" }}
    // <</Stencil::Block>>
	{{- range $d := (stencil.ApplyTemplate "dependencies" | fromYaml).nodejs.devDependencies }}
	  "{{ $d.name }}": "{{ $d.version }}",
	{{- end }}
  },
  "scripts": {
    // <<Stencil::Block(nodeScripts)>>
{{ file.Block "nodeScripts" }}
    // <</Stencil::Block>>
    "build": "npm-run-all clean tsc",
    "ci": "npm-run-all pretty lint test-ci",
    "clean": "rm -rf dist",
    "lint": "eslint src --ext .ts",
    "lint-fix": "eslint src --ext .ts --fix",
    "pre-commit": "npm-run-all pretty lint",
    "prepublishOnly": "yarn install; yarn build",
    "pretty": "prettier --check \"src/**/*.ts\"",
    "pretty-fix": "prettier --write \"src/**/*.ts\"",
    "test": "NODE_ENV=test jest --watch \"./src/\"",
    "test-ci": "NODE_ENV=test jest \"./src/\"",
    "tsc": "node -r tsconfig-paths/register ./node_modules/.bin/tsc -p tsconfig.production.json && node ./scripts/copy-definitions.js"
  },
  "moduleDirectories": [
    "node_modules",
    "src"
  ],
  "moduleFileExtensions": [
    "ts",
    "js"
  ]
}
