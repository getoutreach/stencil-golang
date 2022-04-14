require "{{ .appName }}_client/{{ .appName }}_pb"
require "{{ .appName }}_client/{{ .appName }}_services_pb"

module {{ .titleName }}Client
  class Client < {{ .titleName }}::Stub
    class Interceptor < GRPC::ClientInterceptor
      def initialize(token)
        @token = token
      end

      def request_response(request:, call:, method:, metadata:)
        intercept(request: request, call: call, method: method, metadata: metadata) do
          yield
        end
      end

      def client_streamer(request:, call:, method:, metadata:)
        intercept(request: request, call: call, method: method, metadata: metadata) do
          yield
        end
      end

      def server_streamer(request:, call:, method:, metadata:)
        intercept(request: request, call: call, method: method, metadata: metadata) do
          yield
        end
      end

      def bidi_streamer(request:, call:, method:, metadata:)
        intercept(request: request, call: call, method: method, metadata: metadata) do
          yield
        end
      end

      private

      def intercept(request:, call:, method:, metadata:)
        if metadata["authorization"].nil? &&  @token
          metadata["authorization"] = "Bearer #{@token}"
        end

        yield
      end
    end

    def initialize(host, token, interceptors: [])
      super(host, :this_channel_is_insecure, interceptors: interceptors.push(Interceptor.new(token)))
    end
  end

  def self.create(bento, token, interceptors: [])
    host = "{{ .appName }}.{{ .appName }}--#{bento}.svc.cluster.local:5000"
    Client.new(host, token, interceptors: interceptors)
  end
end
