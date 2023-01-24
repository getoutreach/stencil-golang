{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
variable P1_notify {
  type = list(string)
  default = []
}
variable P2_notify {
  type = list(string)
  default = []
}
variable additional_dd_tags {
  type = list(string)
  default = []
}

variable cpu_high_threshold {
  type = number
  default = 80
}

# window in minutes
variable cpu_high_window { 
  type = number
  default = 30
}

# Number of restarts per 30m to be considered a P1 incident.
variable pod_restart_threshold {
  type = number
  default = 3
}

variable "alert_on_panics" {
  type        = bool
  default     = true
  description = "Enables/Disables the panics monitor defined based on the logs"
}

locals {
  ddTags = concat(["{{ .Config.Name }}", "team:{{  stencil.Arg "reportingTeam" }}"], var.additional_dd_tags)
}

resource "datadog_monitor" "argocd_application_health_status" {
  type = "query alert"
  name = "{{ .Config.Name | title }} argocd application health status"
  query = "max({{ stencil.Arg "terraform.datadog.monitoring.argocd.appHealth.evaluationWindow" | default "last_15m"}}):default_zero(clamp_max(sum:argocd_application_controller.argocd_app_info{name:{{ .Config.Name }},health_status:healthy} by {cluster_name}.fill(zero, 3), 1)) < 1"
  tags = local.ddTags
  message = <<EOF
  ArgoCD Health status has been unhealthy over the window {{ stencil.Arg "terraform.datadog.monitoring.argocd.appHealth.evaluationWindow" | default "last_15m"}}.
  Note: This monitor will auto-resolve after a Healthy status is reported within the specified evaluation timeframe
  Runbook: "https://outreach-io.atlassian.net/wiki/spaces/DT/pages/2390589626/ArgoCD+Runbooks"
  {{- if (stencil.Arg "terraform.datadog.monitoring.argocd.appHealth.notify") }}
  Notify: ${join(" ", var.P2_notify)}
  {{- end }}
  EOF
  require_full_window = false
}

resource "datadog_monitor" "argocd_application_sync_status" {
  type = "query alert"
  name = "{{ .Config.Name | title }} argocd application sync status"
  query = "max({{ stencil.Arg "terraform.datadog.monitoring.argocd.syncStatus.evaluationWindow" | default "last_15m"}}):default_zero(clamp_max(sum:argocd_application_controller.argocd_app_info{name:{{ .Config.Name }},sync_status:synced} by {cluster_name}.fill(zero, 3), 1)) < 1"
  tags = local.ddTags
  message = <<EOF
  ArgoCD Sync status has not been synced over the window {{ stencil.Arg "terraform.datadog.monitoring.argocd.appHealth.evaluationWindow" | default "last_15m"}}.
  Note: This monitor will auto-resolve after a Synced status is reported within the specified evaluation timeframe
  Runbook: "https://outreach-io.atlassian.net/wiki/spaces/DT/pages/2390589626/ArgoCD+Runbooks"
  {{- if (stencil.Arg "terraform.datadog.monitoring.argocd.syncStatus.notify") }}
  Notify: ${join(" ", var.P2_notify)}
  {{- end }}
  EOF
  require_full_window = false
}

# splitting the interval 15 mins to 3 windows (moving rollup by 5mins) and if each of them contains restart -> alert
resource "datadog_monitor" "pod_restarts" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Pod Restarts > 0 last 15m"
  query = "min(last_15m):moving_rollup(diff(sum:kubernetes_state.container.restarts{kube_container_name:{{ .Config.Name }},!env:development} by {kube_namespace}), 300, 'sum') > 0"
  tags = local.ddTags
  message = <<EOF
  If we ever have a pod restart, we want to know.
  Note: This monitor will auto-resolve after 15 minutes of no restarts.
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/pod-restarts.md"
  Notify: ${join(" ", var.P2_notify)}
  EOF
  require_full_window = false
}

resource "datadog_monitor" "pod_restarts_high" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Pod Restarts > ${var.pod_restart_threshold} last 30m"
  query = "max(last_30m):diff(sum:kubernetes_state.container.restarts{kube_container_name:{{ .Config.Name }},!env:development} by {kube_namespace}) > ${var.pod_restart_threshold}"
  tags = local.ddTags
  message = <<EOF
  Several pods are being restarted.
  Note: This monitor will auto-resolve after 30 minutes of no restarts.
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/pod-restarts.md"
  Notify: ${join(" ", var.P1_notify)}
  EOF
  require_full_window = false
}

# default to 0 if the pod was running on high CPU and then stopped/killed
resource "datadog_monitor" "pod_cpu_high" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Pod CPU > ${var.cpu_high_threshold}% of limit last ${var.cpu_high_window}m"
  query = "avg(last_${var.cpu_high_window}m):100 * (default_zero(avg:kubernetes.cpu.usage.total{app:{{ .Config.Name }},!env:development} by {kube_namespace,pod_name}) / 1000000000) / avg:kubernetes.cpu.limits{app:{{ .Config.Name }},!env:development} by {kube_namespace,pod_name} >= ${var.cpu_high_threshold}"
  tags = local.ddTags
  message = <<EOF
  One of the service's pods has been using over ${var.cpu_high_threshold}% of its limit CPU on average for the last ${var.cpu_high_window} minutes.  This almost certainly means that the service needs more CPU to function properly and is being throttled in its current form.
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/pod-cpu.md"
  Notify: ${join(" ", var.P2_notify)}
  EOF
  require_full_window = false
}

resource "datadog_monitor" "pod_memory_rss_high" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Pod Memory.rss > 80% of limit last 30m"
  query = "avg(last_30m):moving_rollup(default_zero(100 * avg:kubernetes.memory.rss{app:{{ .Config.Name }},!env:development} by {kube_namespace,pod_name} / avg:kubernetes.memory.limits{app:{{ .Config.Name }},!env:development} by {kube_namespace,pod_name}), 60, 'max') >= 80"
  tags = local.ddTags
  message = <<EOF
  One of the service's pods has been using over 80% of its limit memory on average for the last 30 minutes.  This almost certainly means that the service needs more memory to function properly and is being throttled in its current form due to GC patterns and/or will be OOMKilled if consumption increases.
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/pod-memory.md"
  Notify: ${join(" ", var.P2_notify)}
  EOF
  require_full_window = false
}

resource "datadog_monitor" "pod_memory_working_set_high" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Pod Memory.working_set > 80% of limit last 30m"
  query = "avg(last_30m):moving_rollup(default_zero(100 * avg:kubernetes.memory.working_set{app:{{ .Config.Name }},!env:development} by {kube_namespace,pod_name} / avg:kubernetes.memory.limits{app:{{ .Config.Name }},!env:development} by {kube_namespace,pod_name}), 60, 'max') >= 80"
  tags = local.ddTags
  message = <<EOF
  One of the service's pods has been using over 80% of its limit memory on average for the last 30 minutes.  This almost certainly means that the service needs more memory to function properly and is being throttled in its current form due to GC patterns and/or will be OOMKilled if consumption increases.
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/pod-memory.md"
  Notify: ${join(" ", var.P2_notify)}
  EOF
  require_full_window = false
}

variable available_pods_low_count {
  type    = number
  default = {{ stencil.Arg "terraform.datadog.pods.thresholds.availableLowCount" | default 2 }}
}

resource "datadog_monitor" "available_pods_low" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Available Pods Low"
  query = "max(last_10m):avg:kubernetes_state.deployment.replicas_available{deployment:{{ .Config.Name }},env:production} by {kube_namespace} < ${var.available_pods_low_count}"
  tags = local.ddTags
  message = <<EOF
  The {{ .Config.Name | title }} replica count should be at least ${var.available_pods_low_count}, which is also the PDB.  If it's lower, that's below the PodDisruptionBudget and we're likely headed toward a total outage of {{ .Config.Name | title }}.
  Note: This P1 alert only includes production
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/available-pods-low.md"
  Notify: ${join(" ", var.P1_notify)}
  EOF
}

resource "datadog_monitor" "panics" {
  type    = "log alert"
  name    = "{{ .Config.Name | title }} Service panics"
  query   = "logs(\"panic status:error service:{{ .Config.Name }} -env:development\").index(\"*\").rollup(\"count\").by(\"kube_namespace\").last(\"5m\") > 0"
  tags    = local.ddTags
  message = <<EOF
  Log based monitor of runtime error panics.
  Note: This P1 alert only includes production
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/service-panics.md"
  Notify: ${join(" ", var.P1_notify)}
  EOF
}

resource "datadog_downtime" "panics_silence" {
  scope      = ["*"]
  monitor_id = datadog_monitor.panics.id
  count      = var.alert_on_panics ? 0 : 1
}

{{- if has "http" (stencil.Arg "serviceActivities") }}
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
{{- end }}

{{- if has "grpc" (stencil.Arg "serviceActivities") }}
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

resource "datadog_service_level_objective" "grpc_p99_latency" {
  name        = "{{ .Config.Name | title }} GRPC P99 Latency"
  type        = "monitor"
  description = "Keeping track of P99 latency commitments for all {{ .Config.Name | title }} GRPC requests in aggregate, for production bentos only."
  tags = local.ddTags
  monitor_ids = [module.grpc_latency_high.high_traffic_id]
  groups = [
    {{- $bentos := extensions.Call "github.com/getoutreach/stencil-discovery.Bentos" (stencil.Arg "deployment.environments") (stencil.Arg "deployment.serviceDomains") }}
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

{{- if has "temporal" (stencil.Arg "serviceActivities") }}
resource "datadog_monitor" "temporal_frontend_pod_restarts" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Temporal Frontend Pod Restarts > 3 last 30m"
  query = "max(last_30m):diff(sum:kubernetes_state.container.restarts{kube_container_name:temporal-frontend,kube_namespace:{{ stencil.ApplyTemplate "goPackageSafeName" }}*,!env:development} by {kube_namespace}) > 3"
  tags = local.ddTags
  message = <<EOF
  If we ever have a pod restart, we want to know.
  Note: This monitor will auto-resolve after 30 minutes of no restarts.
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/pod-restarts.md"
  Notify: ${join(" ", var.P1_notify)}
  EOF
  require_full_window = false
}

resource "datadog_monitor" "temporal_worker_pod_restarts" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Temporal Worker Pod Restarts > 3 last 30m"
  query = "max(last_30m):diff(sum:kubernetes_state.container.restarts{kube_container_name:temporal-worker,kube_namespace:{{ stencil.ApplyTemplate "goPackageSafeName" }}*,!env:development} by {kube_namespace}) > 3"
  tags = local.ddTags
  message = <<EOF
  If we ever have a pod restart, we want to know.
  Note: This monitor will auto-resolve after 30 minutes of no restarts.
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/pod-restarts.md"
  Notify: ${join(" ", var.P1_notify)}
  EOF
  require_full_window = false
}

resource "datadog_monitor" "temporal_matching_pod_restarts" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Temporal Matching Pod Restarts > 3 last 30m"
  query = "max(last_30m):diff(sum:kubernetes_state.container.restarts{kube_container_name:temporal-matching,kube_namespace:{{ stencil.ApplyTemplate "goPackageSafeName" }}*,!env:development} by {kube_namespace}) > 3"
  tags = local.ddTags
  message = <<EOF
  If we ever have a pod restart, we want to know.
  Note: This monitor will auto-resolve after 30 minutes of no restarts.
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/pod-restarts.md"
  Notify: ${join(" ", var.P1_notify)}
  EOF
  require_full_window = false
}

resource "datadog_monitor" "temporal_history_pod_restarts" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Temporal History Pod Restarts > 3} last 30m"
  query = "max(last_30m):diff(sum:kubernetes_state.container.restarts{kube_container_name:temporal-history,kube_namespace:{{ stencil.ApplyTemplate "goPackageSafeName" }}*,!env:development} by {kube_namespace}) > 3"
  tags = local.ddTags
  message = <<EOF
  If we ever have a pod restart, we want to know.
  Note: This monitor will auto-resolve after 30 minutes of no restarts.
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/pod-restarts.md"
  Notify: ${join(" ", var.P1_notify)}
  EOF
  require_full_window = false
}

resource "datadog_monitor" "temporal_frontend_available_pods_low" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Available Temporal frontend Pods Low"
  query = "max(last_10m):avg:kubernetes_state.deployment.replicas_available{deployment:temporal-frontend,kube_namespace:{{ stencil.ApplyTemplate "goPackageSafeName" }}*,env:production} by {kube_namespace} < ${var.available_pods_low_count}"
  tags = local.ddTags
  message = <<EOF
  The {{ .Config.Name | title }} temporal frontend replica count should be at least ${var.available_pods_low_count}, which is also the PDB. If it's lower, that's below the PodDisruptionBudget and we're likely headed toward a total outage of {{ .Config.Name | title }}.
  Note: This P1 alert only includes production
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/available-pods-low.md"
  Notify: ${join(" ", var.P1_notify)}
  EOF
}

resource "datadog_monitor" "temporal_history_available_pods_low" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Available Temporal history Pods Low"
  query = "max(last_10m):avg:kubernetes_state.deployment.replicas_available{deployment:temporal-history,kube_namespace:{{ stencil.ApplyTemplate "goPackageSafeName" }}*,env:production} by {kube_namespace} < ${var.available_pods_low_count}"
  tags = local.ddTags
  message = <<EOF
  The {{ .Config.Name | title }} temporal history replica count should be at least ${var.available_pods_low_count}, which is also the PDB. If it's lower, that's below the PodDisruptionBudget and we're likely headed toward a total outage of {{ .Config.Name | title }}.
  Note: This P1 alert only includes production
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/available-pods-low.md"
  Notify: ${join(" ", var.P1_notify)}
  EOF
}

resource "datadog_monitor" "temporal_matching_available_pods_low" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Available Temporal matching Pods Low"
  query = "max(last_10m):avg:kubernetes_state.deployment.replicas_available{deployment:temporal-matching,kube_namespace:{{ stencil.ApplyTemplate "goPackageSafeName" }}*,env:production} by {kube_namespace} < ${var.available_pods_low_count}"
  tags = local.ddTags
  message = <<EOF
  The {{ .Config.Name | title }} temporal matching replica count should be at least ${var.available_pods_low_count}, which is also the PDB. If it's lower, that's below the PodDisruptionBudget and we're likely headed toward a total outage of {{ .Config.Name | title }}.
  Note: This P1 alert only includes production
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/available-pods-low.md"
  Notify: ${join(" ", var.P1_notify)}
  EOF
}

resource "datadog_monitor" "temporal_worker_available_pods_low" {
  type = "query alert"
  name = "{{ .Config.Name | title }} Available Temporal worker Pods Low"
  query = "max(last_10m):avg:kubernetes_state.deployment.replicas_available{deployment:temporal-worker,kube_namespace:{{ stencil.ApplyTemplate "goPackageSafeName" }}*,env:production} by {kube_namespace} < ${var.available_pods_low_count}"
  tags = local.ddTags
  message = <<EOF
  The {{ .Config.Name | title }} temporal worker replica count should be at least ${var.available_pods_low_count}, which is also the PDB. If it's lower, that's below the PodDisruptionBudget and we're likely headed toward a total outage of {{ .Config.Name | title }}.
  Note: This P1 alert only includes production
  Runbook: "https://github.com/getoutreach/{{ .Config.Name }}/blob/main/documentation/runbooks/available-pods-low.md"
  Notify: ${join(" ", var.P1_notify)}
  EOF
}
{{- end }}

// <<Stencil::Block(tfCustomDatadog)>>
{{ file.Block "tfCustomDatadog" }}
// <</Stencil::Block>>
