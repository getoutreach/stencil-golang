{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
{{- if (stencil.Arg "terraform.datadog.monitoring.generateSLOs") -}}
{{- if has "http" (stencil.Arg "serviceActivities") }}
resource "datadog_service_level_objective" "http_success" {
  name        = "{{ .Config.Name | title }} HTTP Success Response"
  type        = "metric"
  description = "Comparing 5xx responses to all requests as a ratio, broken out by bento."
  tags = local.ddTags
  query {
    numerator   = "clamp_min(default_zero(count:${local.http_request_seconds}{!status:5xx, !env:development,app:{{ stencil.ApplyTemplate "goPackageSafeName" }}} by {kube_namespace}.as_count()), 1)"
    denominator = "clamp_min(default_zero(count:${local.http_request_seconds}{*, !env:development,app:{{ stencil.ApplyTemplate "goPackageSafeName" }}} by {kube_namespace}.as_count()), 1)"
  }
  thresholds {
    timeframe = "7d"
    target = 99.9
    warning = 99.95
  }
}
{{- end }}

{{- if has "grpc" (stencil.Arg "serviceActivities") }}
resource "datadog_service_level_objective" "grpc_success" {
  name        = "{{ .Config.Name | title }} GRPC Success Response"
  type        = "metric"
  description = "Comparing (status:ok) responses to all requests as a ratio, broken out by bento."
  tags = local.ddTags
  query {
    numerator   = "clamp_min(default_zero(count:${local.grpc_request_source}{${join(", ", var.grpc_tags)},app:{{ stencil.ApplyTemplate "goPackageSafeName" }}, !statuscategory:categoryservererror} by {kube_namespace}.as_count()), 1)"
    denominator = "clamp_min(default_zero(count:${local.grpc_request_source}{${join(", ", var.grpc_tags)},app:{{ stencil.ApplyTemplate "goPackageSafeName" }}} by {kube_namespace}.as_count()), 1)"
  }
  thresholds {
    timeframe = "7d"
    target = 99.9
    warning = 99.95
  }
}
{{- end }}

{{- range (stencil.GetModuleHook "monitoring.slos") }}
{{ . }}
{{- end }}

{{- end }}

// <<Stencil::Block(tfCustomSLODatadog)>>
{{ file.Block "tfCustomSLODatadog" }}
// <</Stencil::Block>>
