# List of metrics used in Go services

Bellow is a list of Prometheus metrics registered by Go services in Outreach, categorized based on their source.

Only a subset of those metrics should be whitelisted by default for all Go services + their custom metrics.

## Outreach libraries

### clerk

Source: https://github.com/getoutreach/clerk/blob/15a9ff8ec67108d63ccebd82d642c7826331c2ca/internal/metrics/
  
- clerk_consumer_commit_latency
- clerk_consumer_e2e_event_adjusted
- clerk_consumer_e2e_event_handled
- clerk_consumer_event_count
- clerk_consumer_event_handler
- clerk_consumer_fetch_latency
- clerk_consumer_internal_error_count
- clerk_consumer_rebalance_count
- clerk_producer_write_latency
- clerk_dlq_write_latency
- clerk_producer_event_count

### smartstore

Source: https://github.com/getoutreach/database-monitoring

- smartstore_sql_idle_connections
- smartstore_sql_in_use_connections
- smartstore_sql_max_idle_closed_total
- smartstore_sql_max_idle_time_closed_total
- smartstore_sql_max_lifetime_closed_total
- smartstore_sql_max_open_connections
- smartstore_sql_open_connections
- smartstore_sql_wait_count_total
- smartstore_sql_wait_duration_seconds_total

Source: https://github.com/getoutreach/smartstore/blob/c339c57bd14e3f87727968b48935c99111ed40c0/internal/sharding/sharding.go#L74

- org_shard_cache_miss

Source: https://github.com/getoutreach/smartstore/blob/c339c57bd14e3f87727968b48935c99111ed40c0/pkg/connection/telemetry.go#L41

- connection_borrow
- connection_return

### searchindexer

Source: https://github.com/getoutreach/searchindexer/blob/446d91d30bf86440a490d38fc0f67933dd323cc6/internal/searchindexer/metrics/metrics.go

- basic_expand_max_items
- expand_max_items

Source: https://github.com/getoutreach/searchindexer/blob/446d91d30bf86440a490d38fc0f67933dd323cc6/internal/searchindexer/metrics/metrics_partition_balancer.go

- extra_delay_coefficient
- overflow_randomization
- standard_area_size
- standard_latency_target
- update_interval

### searchquerylib

Source: https://github.com/getoutreach/searchquerylib/blob/2a1a3528d909630c4beafef82fbdc47675d27f6d/pkg/client/metrics/prometheus.go#L50

- searchquerylib_es_call_time

### httpx metrics
Source: https://github.com/getoutreach/httpx/blob/ec48b939121d1c5d460729cf5e74ac46defb8fcd/pkg/metrics/metrics.go
  
- http_client_request_seconds
- http_client_response_bytes
- http_request_bytes
- http_request_seconds
- http_response_bytes
- svc_connection_duration
- svc_connection_state_transistion
- svc_net_connection_active
- svc_net_connection_closed
- svc_net_connection_hijacked
- svc_net_connection_idle
- svc_net_connection_new
- svc_request_seconds

###  redis

Source: ToDo

- redis_redis_1_pool_conn_idle_current
- redis_redis_1_pool_conn_stale_total
- redis_redis_1_pool_conn_total_current
- redis_redis_1_pool_hit_total
- redis_redis_1_pool_miss_total
- redis_redis_1_pool_timeout_total
- redis_redis_2_pool_conn_idle_current
- redis_redis_2_pool_conn_stale_total
- redis_redis_2_pool_conn_total_current
- redis_redis_2_pool_hit_total
- redis_redis_2_pool_miss_total
- redis_redis_2_pool_timeout_total

### rabbitmq

Source: https://github.com/getoutreach/rabbitmq-monitor/blob/1b0d7b968f0ab3a298c896acdfb506f353ece00d/pkg/metrics/measures.go

- messaging_rabbitmq_channel_opened
- messaging_rabbitmq_publish_confirm_seconds
- messaging_rabbitmq_publish_counter
- messaging_rabbitmq_publish_message_size_bytes

### stencil-graphql

Source: https://github.com/getoutreach/stencil-graphql/blob/ae8c612840e3a477644573915b6c542207495c7c/pkg/metrics/metrics.go#L56
  
- graphql_request_duration
- graphql_resolver_duration

### gobox

Source: https://github.com/getoutreach/gobox/blob/2051e8be3e84485ecada4e4f3a9fe140662010cd/pkg/metrics/metrics.go#L119
  
- outbound_call_seconds
- http_request_handled

### monitoring-terraform

Source: https://github.com/getoutreach/monitoring-terraform/pull/1834/files
  
- grpc_request_handled


### services

Source: https://github.com/getoutreach/services/blob/main/pkg/stateguard/http_middleware.go

- stateguard_http_request_count 
         

## Go runtime metrics

### Garbage Collection & Memory

- **go_gc_duration_seconds**
  Summary of the wall-time pause (stop-the-world) duration for each Go garbage collection cycle (in seconds).
- **go_gc_gogc_percent**
  Heap size target percentage configured by the user (default 100). Controlled via the `GOGC` environment variable or `runtime/debug.SetGCPercent`.
- **go_gc_gomemlimit_bytes**
  Go runtime memory limit in bytes configured by the user (default `math.MaxInt64`). Controlled via the `GOMEMLIMIT` environment variable or `runtime/debug.SetMemoryLimit`.
- **go_memstats_alloc_bytes**
  Bytes allocated in the heap and currently in use.
- **go_memstats_alloc_bytes_total**
  Total bytes ever allocated in the heap since process start (cumulative, including freed memory).
- **go_memstats_buck_hash_sys_bytes**
  Bytes used by the profiling bucket hash table.
- **go_memstats_frees_total**
  Total number of heap objects freed.
- **go_memstats_gc_sys_bytes**
  Bytes used for garbage collection system metadata.
- **go_memstats_heap_alloc_bytes**
  Heap bytes allocated and currently in use (same value as `go_memstats_alloc_bytes`).
- **go_memstats_heap_idle_bytes**
  Heap bytes obtained from the system and currently idle (not in use).
- **go_memstats_heap_inuse_bytes**
  Heap bytes that are actively in use.
- **go_memstats_heap_objects**
  Number of currently allocated heap objects.
- **go_memstats_heap_released_bytes**
  Heap bytes released back to the operating system.
- **go_memstats_heap_sys_bytes**
  Total heap bytes obtained from the system.
- **go_memstats_last_gc_time_seconds**
  Unix timestamp (seconds since 1970) of the last completed garbage collection.
- **go_memstats_mallocs_total**
  Total number of heap object allocations since process start.
- **go_memstats_mcache_inuse_bytes**
  Bytes currently in use by the Go mcache allocator.
- **go_memstats_mcache_sys_bytes**
  Bytes obtained from the system for mcache structures.
- **go_memstats_mspan_inuse_bytes**
  Bytes currently in use by Go mspan structures.
- **go_memstats_mspan_sys_bytes**
  Bytes obtained from the system for mspan structures (in use and free).
- **go_memstats_next_gc_bytes**
  Target heap size in bytes that will trigger the next garbage collection.
- **go_memstats_other_sys_bytes**
  Bytes used by other system allocations not accounted for elsewhere.
- **go_memstats_stack_inuse_bytes**
  Bytes currently in use by goroutine stacks.
- **go_memstats_stack_sys_bytes**
  Bytes obtained from the system for all goroutine stacks.
- **go_memstats_sys_bytes**
  Total bytes obtained from the system for all memory allocations.
- **go_memstats_lookups_total**
  Number of pointer dereferences

### Goroutines & Runtime Info

- **go_goroutines**
  Number of goroutines that currently exist.
- **go_info**
  Static information about the Go environment (for example, Go version), exposed as a metric with a `version` label.
- **go_sched_gomaxprocs_threads**
  Current `GOMAXPROCS` value — the maximum number of OS threads that can execute Go code simultaneously.
- **go_threads**
  Number of operating system threads created by the Go runtime.

### Go SQL metrics

- go_sql_idle_connections
- go_sql_in_use_connections
- go_sql_max_idle_closed_total
- go_sql_open_connections
- go_sql_wait_count_total
- go_sql_wait_duration_seconds_total


## Public libraries

### prometheus golang client

Source: https://github.com/prometheus/client_golang/blob/fb0838f53562be13697118c31d95d8cb9dc8c470/prometheus/process_collector.go

- process_cpu_seconds_total
- process_max_fds
- process_network_receive_bytes_total
- process_network_transmit_bytes_total
- process_open_fds
- process_resident_memory_bytes
- process_start_time_seconds
- process_virtual_memory_bytes
- process_virtual_memory_max_bytes

Source: https://github.com/prometheus/client_golang/blob/fb0838f53562be13697118c31d95d8cb9dc8c470/prometheus/promhttp/http.go

- promhttp_metric_handler_requests_in_flight
- promhttp_metric_handler_requests_total

### goresilience

Source: https://github.com/slok/goresilience/blob/3163dfcb956c6ada224984dbf6a237137c1010ba/metrics/prometheus.go

- goresilience_command_execution_duration_seconds
- goresilience_concurrencylimit_inflight_executions
- goresilience_concurrencylimit_limiter_limit
- goresilience_concurrencylimit_result_total

### Tally metrics

- tally_internal_counter_cardinality
- tally_internal_gauge_cardinality
- tally_internal_histogram_cardinality
- tally_internal_num_active_scopes

### Temporal metrics

- temporal_activity_execution_failed
- temporal_activity_execution_latency
- temporal_activity_poll_no_task
- temporal_activity_succeed_endtoend_latency
- temporal_long_request
- temporal_long_request_attempt
- temporal_long_request_failure
- temporal_long_request_failure_attempt
- temporal_long_request_latency
- temporal_long_request_latency_attempt
- temporal_num_pollers
- temporal_poller_start
- temporal_request
- temporal_request_attempt
- temporal_request_failure
- temporal_request_failure_attempt
- temporal_request_latency
- temporal_request_latency_attempt
- temporal_sticky_cache_hit
- temporal_sticky_cache_size
- temporal_sticky_cache_total_forced_eviction
- temporal_worker_start
- temporal_worker_task_slots_available
- temporal_worker_task_slots_used
- temporal_workflow_completed
- temporal_workflow_endtoend_latency
- temporal_workflow_failed
- temporal_workflow_task_execution_latency
- temporal_workflow_task_queue_poll_empty
- temporal_workflow_task_queue_poll_succeed
- temporal_workflow_task_replay_latency
- temporal_workflow_task_schedule_to_start_latency
- temporal_workflow_continue_as_new
