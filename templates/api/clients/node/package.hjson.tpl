{
  // This file is not automatically turned into package.json
  // In order to do so, run: `make gogenerate` in the root
  // of this repository.

  "name": "@outreach/{{ .Config.Name }}-client",
  "version": "0.0.1",
  "description": "{{ .Config.Name }} client implementation",
  "main": "dist/index.js",
  "repository": "https://github.com/getoutreach/{{ .Config.Name }}",
  "files": [
    ///Block(nodeDistFiles)
{{ file.Block "nodeDistFiles" }}
    ///EndBlock(nodeDistFiles)
    "dist"
  ],
  "license": "UNLICENSED",
  "dependencies": {
    ///Block(nodeDependencies)
{{ file.Block "nodeDependencies" }}
    ///EndBlock(nodeDependencies)
	{{- range $d := .bootstrap_dependencies.NodeClient.Dependencies }}
	  "{{ $d.Name }}": "{{ $d.Version }}",
	{{- end }}
  },
  "devDependencies": {
    ///Block(nodeDevDependencies)
{{ file.Block "nodeDevDependencies" }}
    ///EndBlock(nodeDevDependencies)
	{{- range $d := .bootstrap_dependencies.NodeClient.DevDependencies }}
	  "{{ $d.Name }}": "{{ $d.Version }}",
	{{- end }}
  },
  "scripts": {
    ///Block(nodeScripts)
{{ file.Block "nodeScripts" }}
    ///EndBlock(nodeScripts)
    "build": "npm-run-all clean pretty lint tsc",
    "ci": "npm-run-all pretty lint test-ci",
    "clean": "rimraf dist",
    "lint": "eslint src --ext .ts",
    "lint-fix": "eslint src --ext .ts --fix",
    "pre-commit": "npm-run-all pretty lint",
    "prepublishOnly": "yarn build",
    "pretty": "prettier -l \"src/**/*.ts\"",
    "pretty-fix": "prettier --write \"src/**/*.ts\"",
    "test": "NODE_ENV=test jest --watch \"./src/\"",
    "test-ci": "NODE_ENV=test jest \"./src/\"",
    "tsc": "node -r tsconfig-paths/register ./node_modules/.bin/tsc -p tsconfig.production.json && node ./scripts/copy-definitions.js"
  },
  "prettier": "@outreach/prettier-config",
  "moduleDirectories": [
    "node_modules",
    "src"
  ],
  "moduleFileExtensions": [
    "ts",
    "js"
  ]
}
