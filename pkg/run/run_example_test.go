package run_test

import (
	"context"
	"fmt"

	"github.com/getoutreach/gobox/pkg/async"
	"github.com/getoutreach/stencil-golang/pkg/run"
)

func Example() {
	// this is a service that prints the string "hello world" and then exits
	err := run.Run(
		context.Background(),
		"example-service",
		run.WithRunner("greeter", async.Func(func(ctx context.Context) error {
			fmt.Println("hello world")
			return nil
		})),
	)
	if err != nil {
		fmt.Println(err.Error())
	}

	// Output: hello world
}
