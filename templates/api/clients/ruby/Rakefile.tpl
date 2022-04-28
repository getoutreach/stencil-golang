{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "ruby" -}}
require "bundler/gem_tasks"
