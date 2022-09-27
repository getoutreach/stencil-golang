# gRPC

A gRPC service can be created by adding `grpc` to the `arguments.serviceActivities` list, for example a partial `service.yaml` would look like so:

```yaml
arguments:
  serviceActivities:
    - grpc
```

When a gRPC service is created a few additional files will be created, the most important ones are:

- `api/<name>.go` - contains the interface for the client and server
- `api/<name>.proto` - contains the protobuf definition for the service
- `internal/<name>/server.go` - contains the rpc implementation

gRPC, by default, exposes prometheus metrics and traces with the [grpcx](https://github.com/getoutreach/services/tree/main/pkg/grpcx) package. Through this package we also enable reflection by default.

## Adding a New Method

Adding a new method to a gRPC service is a little boilerplate-y at the moment, but pretty simple. First you'll want to define it on the client/server interface at `api/<name>.go` on `Service` interface. For example, let's add a `GetUserByName` function that takes a name (string) and returns an id (string).

We'd add this to the `Service` interface like so:

```go
type Service interface {
  // ... other fields above
  GetUserByName(ctx context.Context, name string) (string, error)
}
```

Next we'd want to define the rpc in the `api/<name>.proto` file. Continuing the example, let's add a `GetUserByName` rpc:

```proto
service AppName {
  // ... other fields above
  rpc GetUserByName (string) returns (string) {}
}
```

We'll want to regenerate the go code, so run `make gogenerate` now to trigger `go generate`.

<!-- TODO(jaredallard): Add the client example when it's moved into here -->

Then we'd go to the server and write the actual implementation. This is done by attaching to the `Server` struct in `internal/<name>/server.go`. Keeping with the example before, `GetUserByName` would look like so:

```go
// GetUserByName returns a user's ID by name
func (s *Server) GetUserByName(ctx context.Context, name string) (string, error) {
  // ...
  return "uuid-goes-here", nil
}
```

**Note**: This doesn't have to go into `server.go` you can create an additional file and attach to the struct, or embed another struct from another package and use that. It's up to you.

If you rebuild the service, you should be able to access your new method! A helpful way of testing this is by running `grpcui` which can be done with `make grpcui`. By default reflection is enabled, so you'll be able to easily see if your method is working or not.
