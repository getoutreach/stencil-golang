# Service Activity Framework

The service activity framework is a simple framework allowing pluggable go-routine powered extension points. All of the features of `stencil-golang` are implemented using this framework (`grpc`, `http`, etc).

## How it Works

The framework is implemented by using the [`async.Runner`](https://github.com/getoutreach/gobox/blob/c8a5b56788ef7a8ad27373c63febf6f993e1a1b0/pkg/async/async.go#L48) interface for every activity. ([`async.Closer`](https://github.com/getoutreach/gobox/blob/c8a5b56788ef7a8ad27373c63febf6f993e1a1b0/pkg/async/async.go#L53) is also implemented for activities that need to close resources.). Each activity is started in [`async.RunGroup`](https://github.com/getoutreach/gobox/blob/c8a5b56788ef7a8ad27373c63febf6f993e1a1b0/pkg/async/async.go#L136) and waits for the following conditions:

 * An activity errors
 * Context is canceled
 * SIGINT is received

When any of those conditions are reached, all activities' are stopped and their `Close()` function (if applicable) is called. It is up to the activities to gracefully shutdown. However, as a special case, if `SIGINT` is received a second time, the program is forcefully terminated. This allows users/service runners to shutdown when needed.

## Adding a custom service activity

<!-- TODO(jaredallard): It'd be nice to have a full tutorial here, but for now this is good -->

A custom service activity can be added by defining a new package in `internal` and consuming it in `main.go`.

Simply add your constructor to `services` block and it will be automatically consumed.
