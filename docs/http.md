# HTTP

**Note**: All services (`service: true`) have a HTTP server by default. This is a private endpoint uses for health/readiness probes as well as service prometheus metrics. This document refers to the public HTTP endpoint.

A public HTTP service can be created by adding `http` to the `arguments.serviceActivities` list, for example a partial `service.yaml` would look like so:

```yaml
arguments:
  serviceActivities:
    - http
```

When a HTTP service is created a few additional files will be created, the most important ones are:

- `internal/<name>/httpservice.go` - contains the HTTP service code, currently contains both the public and private handlers.
- `internal/<name>/handler.go` - contains the handler code, this is where you'll want to add your own handlers as needed.
- `internal/<name>/handler_test.go.tpl` - test code for testing handlers

## Adding a New Handler

Adding a new HTTP handler is pretty simple. The `handler.go` file is currently a static file which means you can change any of it as needed. By default we use [mux](https://github.com/gorilla/mux) to route HTTP requests. Let's add a sample handler to the `handler.go` file:

```go
// Handler returns the main http handler for this service
func Handler() http.Handler {
	svc := &service{}

	routes := mux.NewRouter()

	// Replace this with your routes
  // .. remove ping/pong
	routes.Handle("/users", handlers.Endpoint("users", svc.users))

	return routes
}
```

We can see that the routing logic is in the `Handler` function in `handler.go`, so that's where we added our route for `/users`. Now we'll want to create the handler function. This is done by attaching to the `service` struct.

```go
// users returns ...
func (s *service) users(w http.ResponseWriter, r *http.Request) {
  // .. add your custom logic here, example below
  w.Write([]byte("hello"))
}
```

If we run `make build` and run our service at `./bin/<name>` we'll be able to hit it at `http://localhost:8080/users` and see the response!
