{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
## We use a locals block to have a single point of truth for the metric names, types, and tags that we want all metrics to have
locals {
	# Defines the metric names and types that we want to limit tags for
  metrics = {
		## Go metrics
		"{{ .Config.Name }}.go_gc_cycles_automatic_gc_cycles_total" : "count",
		"{{ .Config.Name }}.go_gc_cycles_forced_gc_cycles_total": "count"
		"{{ .Config.Name }}.go_gc_cycles_total_gc_cycles_total" : "count",
		"{{ .Config.Name }}.go_gc_duration_seconds.count": "gauge",
		"{{ .Config.Name }}.go_gc_duration_seconds.quantile": "gauge",
		"{{ .Config.Name }}.go_gc_duration_seconds.sum": "gauge",
		"{{ .Config.Name }}.go_gc_heap_allocs_by_size_bytes_total": "distribution",
		"{{ .Config.Name }}.go_gc_heap_allocs_bytes_total": "count",
		"{{ .Config.Name }}.go_gc_heap_allocs_objects_total": "count",
		"{{ .Config.Name }}.go_gc_heap_frees_by_size_bytes_total": "distribution",
		"{{ .Config.Name }}.go_gc_heap_frees_bytes_total": "count",
		"{{ .Config.Name }}.go_gc_heap_frees_objects_total": "count",
		"{{ .Config.Name }}.go_gc_heap_goal_bytes" : "gauge",
		"{{ .Config.Name }}.go_gc_heap_objects_objects": "gauge",
		"{{ .Config.Name }}.go_gc_heap_tiny_allocs_objects_total": "count",
		"{{ .Config.Name }}.go_gc_pauses_seconds_total": "distribution",
		"{{ .Config.Name }}.go_goroutines": "gauge",
		"{{ .Config.Name }}.go_info": "gauge",
		"{{ .Config.Name }}.go_memory_classes_heap_free_bytes": "gauge",
		"{{ .Config.Name }}.go_memory_classes_heap_objects_bytes": "gauge",
		"{{ .Config.Name }}.go_memory_classes_heap_released_bytes": "gauge"
		"{{ .Config.Name }}.go_memory_classes_heap_stacks_bytes": "gauge",
		"{{ .Config.Name }}.go_memory_classes_heap_unused_bytes": "gauge",
		"{{ .Config.Name }}.go_memory_classes_metadata_mcache_free_bytes": "gauge",
		"{{ .Config.Name }}.go_memory_classes_metadata_mcache_inuse_bytes": "gauge",
		"{{ .Config.Name }}.go_memory_classes_metadata_mspan_free_bytes": "gauge",
		"{{ .Config.Name }}.go_memory_classes_metadata_mspan_inuse_bytes": "gauge",
		"{{ .Config.Name }}.go_memory_classes_metadata_other_bytes": "gauge",
		"{{ .Config.Name }}.go_memory_classes_os_stacks_bytes": "gauge",
		"{{ .Config.Name }}.go_memory_classes_other_bytes": "gauge",
		"{{ .Config.Name }}.go_memory_classes_profiling_buckets_bytes": "gauge",
		"{{ .Config.Name }}.go_memory_classes_total_bytes": "gauge",
		"{{ .Config.Name }}.go_memstats_alloc_bytes": "gauge",
		"{{ .Config.Name }}.go_memstats_alloc_bytes_total": "count",
		"{{ .Config.Name }}.go_memstats_buck_hash_sys_bytes": "gauge",
		"{{ .Config.Name }}.go_memstats_frees_total": "count",
		"{{ .Config.Name }}.go_memstats_gc_cpu_fraction": "gauge",
		"{{ .Config.Name }}.go_memstats_gc_sys_bytes": "gauge",
		"{{ .Config.Name }}.go_memstats_heap_alloc_bytes": "gauge",
		"{{ .Config.Name }}.go_memstats_heap_idle_bytes": "gauge",
		"{{ .Config.Name }}.go_memstats_heap_inuse_bytes": "gauge",
		"{{ .Config.Name }}.go_memstats_heap_objects": "gauge",
		"{{ .Config.Name }}.go_memstats_heap_released_bytes": "gauge",
		"{{ .Config.Name }}.go_memstats_heap_sys_bytes": "gauge",
		"{{ .Config.Name }}.go_memstats_last_gc_time_seconds": "gauge",
		"{{ .Config.Name }}.go_memstats_lookups_total": "count",
		"{{ .Config.Name }}.go_memstats_mallocs_total": "count",
		"{{ .Config.Name }}.go_memstats_mcache_inuse_bytes": "gauge",
		"{{ .Config.Name }}.go_memstats_mcache_sys_bytes": "gauge",
		"{{ .Config.Name }}.go_memstats_mspan_inuse_bytes": "gauge",
		"{{ .Config.Name }}.go_memstats_mspan_sys_bytes": "gauge",
		"{{ .Config.Name }}.go_memstats_next_gc_bytes": "gauge",
		"{{ .Config.Name }}.go_memstats_other_sys_bytes": "gauge",
		"{{ .Config.Name }}.go_memstats_stack_inuse_bytes": "gauge",
		"{{ .Config.Name }}.go_memstats_stack_sys_bytes": "gauge",
		"{{ .Config.Name }}.go_memstats_sys_bytes": "gauge",
		"{{ .Config.Name }}.go_sched_goroutines_goroutines": "gauge",
		"{{ .Config.Name }}.go_sched_latencies_seconds": "distribution",
		"{{ .Config.Name }}.go_threads": "gauge",
  }

	# Defines the tags to be added to the metrics above -- anything not on this list is not included
  tags = [
    "app",
    "bento",
    "cluster_name",
    "env",
    "reporting_team",
    "pod_name",
    "region",
  ]
}

# Source: https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/metric_tag_configuration
resource "datadog_metric_tag_configuration" "this" {
  for_each    = local.metrics
  metric_name = each.key
  metric_type = each.value
  tags        = local.tags
}
