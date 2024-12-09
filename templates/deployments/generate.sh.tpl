#!/usr/bin/env bash
# This script generates kubernetes config files for all jsonnet files in the deployments folder.
# This way we can easily check what changes are being made to which environment.

ROOT=./deployments/{{ .Config.Name }}
OUTPUT=$ROOT/kubecfg
DOWNLOAD_LIBS=1

if [ $# -eq 1 ] && [ "$1" = "--quick" ]; then
  DOWNLOAD_LIBS=0
fi

# Exit when any command fails
set -e

# Prepare output folder
rm -rf $OUTPUT
mkdir -p $OUTPUT

generate() {
  line=$1

  channel=$(echo "$line" | jq -r '.channel')
  cluster=$(echo "$line" | jq -r '.cluster')
  environment=$(echo "$line" | jq -r '.environment')
  name=$(echo "$line" | jq -r '.name')
  region=$(echo "$line" | jq -r '.region')
  dev_email=$(echo "$line" | jq -r '.dev_email')

  echo "Generating kubernetes config for '$name'"
  kubecfg -J ./deployments/libs show \
    -V "appImageRegistry=gcr.io/outreach-docker" -V "bento=$name" -V "channel=$channel" -V "cluster=$cluster" \
    -V "environment=$environment" -V "namespace={{ .Config.Name }}--$name" -V "region=$region" -V "ts=1656492859" -V "version=v0.0.1" \
    -V "dev_email=$dev_email" \
    $ROOT/{{ .Config.Name }}.jsonnet -oyaml >"$OUTPUT/$name.yaml"
}

# Download libsonnet files
if [ $DOWNLOAD_LIBS -eq 1 ]; then
  rm -rf ./deployments/libs
  mkdir -p ./deployments/libs/kubernetes

  outreach_libs=(app.libsonnet outreach.libsonnet kube.libsonnet cluster.libsonnet database.libsonnet)
  for lib in "${outreach_libs[@]}"; do
    curl -s -o "./deployments/libs/kubernetes/$lib" https://raw.githubusercontent.com/getoutreach/jsonnet-libs/master/kubernetes/"$lib"
  done
  curl -s -o "./deployments/libs/kubernetes/clusters.yaml" http://k8s-clusters.outreach.cloud/
  curl -s -o "./deployments/libs/kubecfg.libsonnet" https://raw.githubusercontent.com/kubecfg/kubecfg/master/lib/kubecfg.libsonnet

  find ./deployments/libs -name '*.libsonnet' -exec jsonnetfmt -i {} +
fi

generate '{"name":"bento1a", "cluster":"none", "region":"none", "channel":"white", "environment":"development", "dev_email":"stub@email"}'
generate '{"name":"staging1a", "cluster":"staging.us-east-2", "region":"us-east-2", "channel":"white", "environment":"staging"}'

generate '{"name":"app1a", "cluster":"production.us-west-2", "region":"us-west-2", "channel":"green", "environment":"production"}'
generate '{"name":"app1b", "cluster":"production.us-west-2", "region":"us-west-2", "channel":"yellow", "environment":"production"}'
generate '{"name":"app1c", "cluster":"production.us-west-2", "region":"us-west-2", "channel":"green", "environment":"production"}'
generate '{"name":"app1d", "cluster":"production.us-west-2", "region":"us-west-2", "channel":"orange", "environment":"production"}'
generate '{"name":"app1e", "cluster":"production.us-west-2", "region":"us-west-2", "channel":"green", "environment":"production"}'
generate '{"name":"app1f", "cluster":"production.us-west-2", "region":"us-west-2", "channel":"green", "environment":"production"}'
generate '{"name":"app2a", "cluster":"production.us-east-1", "region":"us-east-1", "channel":"green", "environment":"production"}'
generate '{"name":"app2b", "cluster":"production.us-east-1", "region":"us-east-1", "channel":"green", "environment":"production"}'
generate '{"name":"app2c", "cluster":"production.us-east-1", "region":"us-east-1", "channel":"green", "environment":"production"}'
generate '{"name":"app4a", "cluster":"production.eu-west-1", "region":"eu-west-1", "channel":"green", "environment":"production"}'

## <<Stencil::Block(extras)>>
{{ file.Block "extras" }}
## <</Stencil::Block>>
