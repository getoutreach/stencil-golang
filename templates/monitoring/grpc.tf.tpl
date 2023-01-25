{{- if not (and (stencil.Arg "service") (has "grpc" (stencil.Arg "serviceActivities"))) -}}
  {{- file.Skip "Not a service" -}}
{{- end -}}
variable grpc_request_source {
  type    = string
  default = "grpc_request_handled"
}

variable grpc_tags {
  type    = list(string)
  default = [{{ QuoteJoinStrings (toStrings (stencil.Arg "terraform.datadog.grpc.tags")) ", " | default "\"*\", \"!env:development\"" }}]
}

variable grpc_evaluation_window {
  type    = string
  default = {{ stencil.Arg "terraform.datadog.grpc.evaluationWindow" | default "last_15m" | quote }}
}

variable grpc_low_count_threshold {
  type   = number
  default = {{ stencil.Arg "terraform.datadog.grpc.lowTrafficCountThreshold" | default 1000 }}
}

variable grpc_qos_low_traffic_threshold {
  type    = number
  default = {{ stencil.Arg "terraform.datadog.grpc.qos.thresholds.lowTraffic" | default 50 }}
}

variable grpc_qos_high_traffic_threshold {
  type   = number
  default = {{ stencil.Arg "terraform.datadog.grpc.qos.thresholds.highTraffic" | default 99 }}
}

locals {
	grpc_request_source = local.prefix ? "{{ stencil.ApplyTemplate "goPackageSafeName" }}.${var.grpc_request_source}" : "${var.grpc_request_source}" 
}

module "grpc_success_rate_low" {
  source = "git@github.com:getoutreach/monitoring-terraform.git//modules/alerts/datadog/low-traffic-composite-monitor"
  name = "{{ .Config.Name | title }} GRPC Success Rate Low"
  tags = local.ddTags
  message = <<EOF
  Composite monitor of GRPC QoS based on traffic
  Calculating the success rate (!statuscategory:categoryservererror) of GRPC requests as a 0-100% monitor.
  High traffic -> ${var.grpc_qos_high_traffic_threshold}%
  Low traffic -> ${var.grpc_qos_low_traffic_threshold}%
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/grpc-success-rate-low.md"
  Notify: ${join(" ", var.P2_notify)}
  EOF
  require_full_window = false
  low_count_query = "sum(${var.grpc_evaluation_window}):clamp_min(default_zero(count:${local.grpc_request_source}{${join(", ", var.grpc_tags)},app:{{ stencil.ApplyTemplate "goPackageSafeName" }}} by {kube_namespace}.as_count()), 1) < ${var.grpc_low_count_threshold}"
  low_traffic_query = "sum(${var.grpc_evaluation_window}):100 * clamp_min(default_zero(count:${local.grpc_request_source}{${join(", ", var.grpc_tags)},app:{{ stencil.ApplyTemplate "goPackageSafeName" }},statuscategory:categoryservererror} by {kube_namespace}.as_count()), 1) / clamp_min(default_zero(count:${local.grpc_request_source}{${join(", ", var.grpc_tags)},app:{{ stencil.ApplyTemplate "goPackageSafeName" }}} by {kube_namespace}.as_count()), 1) >= ${var.grpc_qos_low_traffic_threshold}"
  high_traffic_query = "sum(${var.grpc_evaluation_window}):100 * clamp_min(default_zero(count:${local.grpc_request_source}{${join(", ", var.grpc_tags)},app:{{ stencil.ApplyTemplate "goPackageSafeName" }}, !statuscategory:categoryservererror} by {kube_namespace}.as_count()), 1) / clamp_min(default_zero(count:${local.grpc_request_source}{${join(", ", var.grpc_tags)},app:{{ stencil.ApplyTemplate "goPackageSafeName" }}} by {kube_namespace}.as_count()), 1) < ${var.grpc_qos_high_traffic_threshold}"
}

variable grpc_latency_low_traffic_percentile {
  type    = number
  default = {{ stencil.Arg "terraform.datadog.grpc.latency.percentiles.lowTraffic" | default 90 }}
}

variable grpc_latency_high_traffic_percentile {
  type    = number
  default = {{ stencil.Arg "terraform.datadog.grpc.latency.percentiles.highTraffic" | default 99 }}
}

variable grpc_latency_low_traffic_threshold {
  type    = number
  default = {{ stencil.Arg "terraform.datadog.grpc.latency.thresholds.lowTraffic" | default 2 }}
}

variable grpc_latency_high_traffic_threshold {
  type   = number
  default = {{ stencil.Arg "terraform.datadog.grpc.latency.thresholds.highTraffic" | default 2 }}
}

module "grpc_latency_high" {
  source = "git@github.com:getoutreach/monitoring-terraform.git//modules/alerts/datadog/low-traffic-composite-monitor"
  name = "{{ .Config.Name | title }} GRPC Latency High"
  tags = local.ddTags
  message = <<EOF
  Composite monitor of GRPC request latency based on traffic
  High traffic -> P${var.grpc_latency_high_traffic_percentile}
  Low traffic -> P${var.grpc_latency_low_traffic_percentile}
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/grpc-latency-high.md"
  Notify: ${join(" ", var.P2_notify)}
  EOF
  require_full_window = false
  low_count_query = "sum(${var.grpc_evaluation_window}):clamp_min(default_zero(count:${local.grpc_request_source}{${join(", ", var.grpc_tags)},app:{{ stencil.ApplyTemplate "goPackageSafeName" }}} by {kube_namespace}.as_count()), 1) < ${var.grpc_low_count_threshold}"
  low_traffic_query = "avg(${var.grpc_evaluation_window}):default_zero(p${var.grpc_latency_low_traffic_percentile}:${local.grpc_request_source}{${join(", ", var.grpc_tags)},app:{{ stencil.ApplyTemplate "goPackageSafeName" }}} by {kube_namespace}) > ${var.grpc_latency_low_traffic_threshold}"
  high_traffic_query = "avg(${var.grpc_evaluation_window}):default_zero(p${var.grpc_latency_high_traffic_percentile}:${local.grpc_request_source}{${join(", ", var.grpc_tags)},app:{{ stencil.ApplyTemplate "goPackageSafeName" }}} by {kube_namespace}) > ${var.grpc_latency_high_traffic_threshold}"
}

// <<Stencil::Block(tfCustomGRPCDatadog)>>
{{ file.Block "tfCustomGRPCDatadog" }}
// <</Stencil::Block>>
