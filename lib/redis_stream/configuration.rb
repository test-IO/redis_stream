module RedisStream
  class Configuration
    attr_accessor :client, :group_id, :consumer_id, :stream_key, :logging_stream_key, :max_length

    def initialize
      @group = "group"
      @consumer = "consumer"
      @stream_key = "stream"
      @logging_stream_key = "logging_stream"
      @max_length = 100
    end

    def redis(client)
      @client = client
    end

    def redis_url(url)
      @client = Redis.new(url: url)
    end

    def group(group_id)
      @group_id = group_id
    end

    def consumer(consumer_id)
      @consumer_id = consumer_id
    end

    def stream(stream)
      @stream_key = stream
    end

    def logging_stream(logging_stream)
      @logging_stream_key = logging_stream
    end

    def maxlen(max_length)
      @max_length = max_length
    end
  end
end
