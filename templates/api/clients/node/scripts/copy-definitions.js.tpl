const { build } = require('@outreach/grpc-client');
const path = require('path');

build.copyDefinitions(path.resolve(__dirname, '..'));
