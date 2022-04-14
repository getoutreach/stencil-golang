// +build or_int

package {{ .underscoreAppName }}_test

// The S3 suite illustrates how to test your s3-based code in an
// integration environment (i.e. with a fake S3 service).
// This test can be invoked via `make integration`

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"io"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"

	"github.com/getoutreach/gobox/pkg/shuffler"
	"gotest.tools/v3/assert"
)

func TestS3(t *testing.T) {
	// run the s3 tests in random order
	shuffler.Run(t, s3tests{})
}

type s3tests struct{}

func (s s3tests) TestPutGetObject(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second*30)
	defer cancel()

	bucket, c := s.client(ctx, t)

	// put an object
	put := &s3.PutObjectInput{}
	put = put.SetBucket(bucket).SetKey("key").SetBody(strings.NewReader("hello"))
	_, err := c.PutObjectWithContext(ctx, put)
	assert.Assert(t, err)

	// get the object
	get := &s3.GetObjectInput{}
	get = get.SetBucket(bucket).SetKey("key")
	out, err := c.GetObjectWithContext(ctx, get)
	assert.Assert(t, err)
	defer out.Body.Close()
	body, err := io.ReadAll(out.Body)
	assert.Assert(t, err)
	assert.Equal(t, "hello", string(body))
}

func (s s3tests) client(ctx context.Context, t *testing.T) (bucket string, c *s3.S3) {
	// create a random bucket for each test so that tests don't conflict.
	bucket = s.randomString(t, "bucket")

	cfg := aws.NewConfig().WithEndpoint("http://localhost:9000")
	cfg = cfg.WithDisableSSL(true).WithS3ForcePathStyle(true)
	sess, err := session.NewSession(cfg)
	assert.Assert(t, err)

	c = s3.New(sess, cfg)
	in := &s3.CreateBucketInput{}
	_, err = c.CreateBucketWithContext(ctx, in.SetBucket(bucket))
	assert.Assert(t, err)
	return bucket, c
}

func (s s3tests) randomString(t *testing.T, prefix string) string {
	data := make([]byte, 10)
	_, err := rand.Read(data)
	assert.Assert(t, err)
	return prefix + "-" + strings.ToLower(hex.EncodeToString(data))
}
