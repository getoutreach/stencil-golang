{{- $_ := stencil.ApplyTemplate "skipGrpcClient" "ruby" -}}
source 'https://rubygems.org'

# Declare your gem's dependencies in github_stats.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

## <<Stencil::Block(extraClientGems)>>
{{ file.Block "extraClientGems" }}
## <</Stencil::Block>>
