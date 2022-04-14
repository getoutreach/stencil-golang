const tsConfig = require('./tsconfig.json');
const tsConfigPaths = require('tsconfig-paths');

const baseUrl = './dist'; // Either absolute or relative path. If relative it's resolved to the current working directory.
tsConfigPaths.register({
  baseUrl,
  paths: tsConfig.compilerOptions.paths
});
