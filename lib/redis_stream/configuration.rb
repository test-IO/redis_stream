module RedisStream
  class Configuration
    attr_accessor :client, :group_id, :consumer_id, :stream_key

    def initialize
      @group = "group"
      @consumer = "consumer"
      @stream_key = "stream"
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

    def stream_key(stream_key)
      @stream_key = stream_key
    end
  end
end
