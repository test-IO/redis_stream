# frozen_string_literal: true

module RedisStream
  class Publisher
    def initialize(stream_key)
      @stream_key = stream_key
    end

    def publish(name, data = {})
      data = { "name" => name, "json" => data.to_json }
      RedisStream.client.xadd(@stream_key, data)
    end
  end
end
