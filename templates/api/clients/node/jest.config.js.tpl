{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "node" -}}
module.exports = {
  collectCoverage: true,
  collectCoverageFrom: ['**/src/**'],
  coveragePathIgnorePatterns: ['<rootDir>/src/grpc/'],
  moduleNameMapper: {
    ['@getoutreach/{{ .Config.Name }}-client']: '<rootDir>/src'
  },
  modulePathIgnorePatterns: ['dist', '\\.(json)$'],
  preset: 'ts-jest',
  testEnvironment: 'node',
  verbose: true
};
