// +build or_int

package {{ .underscoreAppName }}_test

// The Kafka suite illustrates how to test your kafka-based code in an
// integration environment (i.e. with a real Kafka service).  Kafka
// fakes do not have good support in Golang yet, so a real version is
// needed.  This test can be invoked via `make integration`

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"testing"
	"time"

	"github.com/getoutreach/services/pkg/find"
	"github.com/getoutreach/services/pkg/find/findtest"

	"github.com/segmentio/kafka-go"

	"github.com/getoutreach/gobox/pkg/shuffler"
	"gotest.tools/v3/assert"
)

func TestKafka(t *testing.T) {
	// run the kafka tests in random order
	shuffler.Run(t, kafkatests{})
}

type kafkatests struct{}

func (k kafkatests) TestProduceConsume(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second*30)
	defer cancel()

	// replace this with strongly typed readers writers or however
	// your package does this.  If your service is mostly a
	// consumer, you can just use the writer here to simulate a
	// producer. Or if your service is a producer, you can use
	// the reader to simulate a consumer.

	_, r, w := k.readerWriter(ctx, t)
	defer r.Close()
	defer w.Close()

	// write a message
	message := kafka.Message{Value: []byte("hello")}
	assert.Assert(t, w.WriteMessages(ctx, message))

	// read the message
	m, err := r.ReadMessage(ctx)
	assert.Assert(t, err)
	assert.Equal(t, "hello", string(m.Value))
}

func (k kafkatests) readerWriter(ctx context.Context, t *testing.T) (string, *kafka.Reader, *kafka.Writer) {
	t.Cleanup(findtest.UseKafkaIntegration())

	// this creates a random top to ensure each test does not
	// interfere with another
	topic := k.randomString(t, "topic")
	consumerGroup := k.randomString(t, "group")
	brokers, err := find.Service(ctx, find.KafkaPublishBrokers)
	assert.Assert(t, err)

	brokers += ":9092"
	conn, err := kafka.Dial("tcp", brokers)
	assert.Assert(t, err)
	defer conn.Close()

	err = conn.CreateTopics(kafka.TopicConfig{
		Topic:             topic,
		NumPartitions:     1,
		ReplicationFactor: 1,
	})
	assert.Assert(t, err)

	w := kafka.NewWriter(kafka.WriterConfig{
		Brokers: []string{brokers},
		Topic:   topic,
	})

	r := kafka.NewReader(kafka.ReaderConfig{
		Brokers: []string{brokers},
		Topic:   topic,
		GroupID: consumerGroup,
	})

	return topic, r, w
}

func (k kafkatests) randomString(t *testing.T, prefix string) string {
	data := make([]byte, 10)
	_, err := rand.Read(data)
	assert.Assert(t, err)
	return prefix + "_" + hex.EncodeToString(data)
}
