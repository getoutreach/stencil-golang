module.exports = {
  extends: ['@outreach/eslint-config/node', 'plugin:jsdoc/recommended'],
  plugins: ['jsdoc', '@typescript-eslint'],
  ignorePatterns: ['*.d.ts', 'publish.js'],
  rules: {
    'node/no-unsupported-features/es-syntax': 'off', // Typescript syntax uses unsupported features in node v10
    'node/no-missing-import': 'off', // The import detection doesn't seem to work with TS and node v10

    // JSDoc rules
    // The param type is redundant with the typescript specified type so is disabled
    'jsdoc/require-param-type': 0,
    'jsdoc/require-returns-type': 0
  },
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 6,
    sourceType: 'module',
    ecmaFeatures: {
      modules: true
    }
  }
};
