{{ file.Skip "Virtual file for .gitignore module hooks" }}

{{- define "goIgnores" }}
# Avoid checking in go.work and friends.
# See: https://github.com/golang/website/commit/80af5f5f42a708fad470699f7f3fe7eb1d1e6851
go.work
go.work.sum
{{- end }}

{{- stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "gitIgnore/extraIgnores" (list (stencil.ApplyTemplate "goIgnores")) }}
