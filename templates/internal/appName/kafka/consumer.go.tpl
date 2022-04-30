{{- if not (has "kafka" (stencil.Arg "serviceActivities")) }}
{{ file.Skip "Not a Kafka service" }}
{{- end }}
{{- $_ := file.SetPath (printf "internal/%s/%s" .Config.Name (base file.Path)) }}
// {{ stencil.ApplyTemplate "copyright" }} 

// Description: This file is responsible for creating consumers of kafka streams.
// Managed: true

package {{ stencil.ApplyTemplate "goPackageSafeName" }} //nolint:revive // Why: We allow [-_].

import (
	"context"
	"errors"
	"fmt"
	"io"

	"github.com/getoutreach/gobox/pkg/async"
	"github.com/getoutreach/gobox/pkg/log"
	"github.com/getoutreach/gobox/pkg/orerr"
	"github.com/getoutreach/gobox/pkg/trace"
	"github.com/segmentio/kafka-go"
)
// loggableMessage is an adapter which allows kafka.Message to be used
// as a log.Marshaler.
type loggableMessage struct {
	kafka.Message
}

// MarshalLog satisfies the log.Marshaler interface.
func (m *loggableMessage) MarshalLog(addField func(field string, v interface{})) {
	addField("kafka.topic", m.Topic)
	addField("kafka.partition", m.Partition)
	addField("kafka.offset", m.Offset)
	addField("kafka.key", m.Key)
	addField("kafka.time", m.Time)
}

// KafkaMessageHandler is a function signature defining how to handle kafka messages
// DEPRECATED - use the 'handlemessage' block instead
type KafkaMessageHandler func(context.Context, kafka.Message, ...log.Marshaler) error

// KafkaConsumerService provides a polling abstraction for kafka messages
type KafkaConsumerService struct {
	reader interface{
		io.Closer
		FetchMessage(context.Context) (kafka.Message, error)
		ReadMessage(context.Context) (kafka.Message, error)
		CommitMessages(context.Context, ...kafka.Message) error
	}
	// DEPRECATED
	handler KafkaMessageHandler
	topic string
	groupID string
	hosts []string

	// place any additional properties here
	///Block(consumerproperties)
{{ file.Block "consumerproperties" }}
	///EndBlock(consumerproperties)
}

// NewKafkaConsumerService initializes and returns a KafkaConsumerService instance
func NewKafkaConsumerService() *KafkaConsumerService {
	svc := KafkaConsumerService{}

	// initialize your consumer here
	///Block(initialization)
{{ file.Block "initialization" }}
	///EndBlock(initialization)

	return &svc
}

func (s *KafkaConsumerService) MarshalLog(addfield func(key string, value interface{})) {
	addfield("hosts", s.hosts)
	addfield("topic", s.topic)
	addfield("groupid", s.groupID)
}

// Run helps to implements the ServiceActivity interface for KafkaConsumerService and
// ultimately serves as entrypoint for the the KafkaConsumerService service activity.
func (s *KafkaConsumerService) Run(ctx context.Context, cfg *Config) error {
	s.hosts = cfg.KafkaHosts
	s.topic = cfg.KafkaConsumerTopic
	s.groupID = cfg.KafkaConsumerGroupID

	s.reader = kafka.NewReader(kafka.ReaderConfig{
		Brokers:  s.hosts,
		Topic:    s.topic,
		GroupID:  s.groupID,
		MinBytes: 10e3, // 10KB
		MaxBytes: 10e6, // 10MB
	})

	s.pollMessages(ctx)

	return ctx.Err()
}

func (s *KafkaConsumerService) Close(_ context.Context) error {
	return s.reader.Close()
}

// pollMessages repeatedly polls the underlying kafka reader for new messages.
func (s *KafkaConsumerService) pollMessages(ctx context.Context) {
	log.Info(ctx, "polling for kafka messages", s)
	tasks := async.NewTasks("kafka-consumer")
	tasks.Loop(ctx, async.Func(func(ctx context.Context) error {
		// This will block until a message is read or the reader detects a
		// canceled context. FetchMessage does not consume the message.
		msg, err := s.reader.FetchMessage(ctx)

		childCtx := trace.StartCall(ctx, "KafkaMessageReceived", s)
		defer trace.End(childCtx)

		if err != nil {
			if !orerr.IsOneOf(err, io.EOF, context.Canceled, context.DeadlineExceeded) {
				_ = trace.SetCallError(childCtx, err) //nolint:errcheck // Why: We can't do anything about this if it errors.
			}
			return err
		}

		// handle the kafka message here
		///Block(handlemessage)
{{ file.Block "handlemessage" }}
		///EndBlock(handlemessage)

		// DEPRECATED.  Use the 'handlemessage' block instead
		if s.handler != nil {
			handlerErr := s.handler(childCtx, msg, &loggableMessage{Message: msg})
			if handlerErr != nil {
				return handlerErr
			}
		}

		// consume messages only once they have been handled.
		return s.reader.CommitMessages(ctx, msg)
	}))
	tasks.Wait()
}
