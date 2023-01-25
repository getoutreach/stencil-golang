{{- if not (and (stencil.Arg "service") (has "http" (stencil.Arg "serviceActivities"))) -}}
  {{- file.Skip "Not a service" -}}
{{- end -}}
variable http_success_rate_low_traffic_percentile {
  type    = number
  default = {{ stencil.Arg "terraform.datadog.http.percentiles.lowTraffic" | default 90 }}
}

variable http_success_rate_high_traffic_percentile {
  type    = number
  default = {{ stencil.Arg "terraform.datadog.http.percentiles.highTraffic" | default 99 }}
}

variable http_success_rate_low_count_threshold {
  type    = number
  default = {{ stencil.Arg "terraform.datadog.http.thresholds.lowCount" | default 1000 }}
}

variable http_success_rate_evaluation_window {
  type    = string
  default = {{ stencil.Arg "terraform.datadog.http.evaluationWindow" | default "last_15m" | quote }}
}

variable http_latency_high_count_threshold {
  type = number
  default = {{ stencil.Arg "terraform.datadog.http.latency.count.highCount" | default 1000 }}
}

variable http_latency_high_low_traffic_threshold {
  type = number
  default = {{ stencil.Arg "terraform.datadog.http.latency.thresholds.lowTraffic" | default 2 }}
}

variable http_latency_high_high_traffic_threshold {
  type = number
  default = {{ stencil.Arg "terraform.datadog.http.latency.thresholds.highTraffic" | default 2 }}
}

locals {
	http_request_seconds = local.prefix ? "{{ stencil.ApplyTemplate "goPackageSafeName" }}.http_request_seconds" : "http_request_seconds" 
}

module "http_success_rate_low" {
  source = "git@github.com:getoutreach/monitoring-terraform.git//modules/alerts/datadog/low-traffic-composite-monitor"
  name = "{{ .Config.Name | title }} HTTP Success Rate Low (P${var.http_success_rate_high_traffic_percentile}H/P${var.http_success_rate_low_traffic_percentile}L)"
  tags = local.ddTags
  message = <<EOF
  Composite monitor calculating the success rate of non-5xx requests as a 0-100% monitor.
  High traffic -> P${var.http_success_rate_high_traffic_percentile}
  Low traffic -> P${var.http_success_rate_low_traffic_percentile}
  Low traffic count < ${var.http_success_rate_low_count_threshold}
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/http-success-rate-low.md"
  Notify: ${join(" ", var.P2_notify)}
  EOF
  require_full_window = false
  low_count_query = "sum(${var.http_success_rate_evaluation_window}):clamp_min(default_zero(count:${local.http_request_seconds}{!status:5xx,!env:development,app:{{ stencil.ApplyTemplate "goPackageSafeName" }}} by {kube_namespace}.as_count()), 1) < ${var.http_success_rate_low_count_threshold}"
  low_traffic_query = "sum(${var.http_success_rate_evaluation_window}):100 * clamp_min(default_zero(count:${local.http_request_seconds}{!status:5xx,!env:development,app:{{ stencil.ApplyTemplate "goPackageSafeName" }}} by {kube_namespace}.as_count()), 1) / clamp_min(default_zero(count:${local.http_request_seconds}{*, !env:development} by {kube_namespace}.as_count()), 1) < ${var.http_success_rate_low_traffic_percentile}"
  high_traffic_query = "sum(${var.http_success_rate_evaluation_window}):100 * clamp_min(default_zero(count:${local.http_request_seconds}{!status:5xx,!env:development,app:{{ stencil.ApplyTemplate "goPackageSafeName" }}} by {kube_namespace}.as_count()), 1) / clamp_min(default_zero(count:${local.http_request_seconds}{*, !env:development,app:{{ stencil.ApplyTemplate "goPackageSafeName" }}} by {kube_namespace}.as_count()), 1) < ${var.http_success_rate_high_traffic_percentile}"
}

module "http_latency_high" {
  source = "git@github.com:getoutreach/monitoring-terraform.git//modules/alerts/datadog/low-traffic-composite-monitor"
  name = "{{ .Config.Name | title }} HTTP Latency High (P99H/P90L)"
  tags = local.ddTags
  message = <<EOF
  Composite monitor based on traffic
  High traffic -> P99
  Low traffic -> P90
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/http-latency-high.md"
  Notify: ${join(" ", var.P2_notify)}
  EOF
  require_full_window = false
  low_count_query = "sum(last_15m):clamp_min(default_zero(count:${local.http_request_seconds}{*, !env:development,app:{{ stencil.ApplyTemplate "goPackageSafeName" }}} by {kube_namespace}.as_count()), 1) < ${var.http_latency_high_count_threshold}"
  low_traffic_query = "avg(last_15m):default_zero(p90:${local.http_request_seconds}{*, !env:development,app:{{ stencil.ApplyTemplate "goPackageSafeName" }}} by {kube_namespace}) > ${var.http_latency_high_low_traffic_threshold}"
  high_traffic_query = "avg(last_15m):default_zero(p99:${local.http_request_seconds}{*, !env:development,app:{{ stencil.ApplyTemplate "goPackageSafeName" }}} by {kube_namespace}) > ${var.http_latency_high_high_traffic_threshold}"
}

resource "datadog_service_level_objective" "http_p99_latency" {
  name        = "{{ .Config.Name | title }} HTTP P99 Latency"
  type        = "monitor"
  description = "Keeping track of P99 latency commitments for all {{ .Config.Name | title }} requests in aggregate, for production bentos only."
  tags = local.ddTags
  monitor_ids = [module.http_latency_high.high_traffic_id]
  groups = [
    {{- $bentos := extensions.Call "github.com/getoutreach/stencil-discovery.Bentos" (stencil.Arg "deployment.environments") (stencil.Arg "deployment.serviceDomains")}}
    {{- range $b := $bentos }}
    "kube_namespace:{{ stencil.ApplyTemplate "goPackageSafeName" }}--{{ $b.name }}",
    {{- end }}
  ]
  thresholds {
    timeframe = "7d"
    target = 99.9
    warning = 99.95
  }
}

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

// <<Stencil::Block(tfCustomHTTPDatadog)>>
{{ file.Block "tfCustomHTTPDatadog" }}
// <</Stencil::Block>>
