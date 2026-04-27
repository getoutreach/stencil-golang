{{- file.Skip "Virtual file for .gitattributes module hooks" }}

{{- define "golangGitAttributes" }}
go.sum linguist-generated
*.pb.go linguist-generated
{{- if has "node" (stencil.Arg "grpcClients") }}
*_pb.d.ts linguist-generated
*_pb.js linguist-generated
{{- end }}
{{- if has "ruby" (stencil.Arg "grpcClients") }}
*_pb.rb linguist-generated
{{- end }}
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "gitattributes/extra" (list (stencil.ApplyTemplate "golangGitAttributes")) }}
