# frozen_string_literal: true

require "json"

module RedisStream
  class Publisher
    def initialize(stream_key)
      @stream_key = stream_key
    end

    def publish(name, data = {})
      data = {"name" => name, "json" => JSON.generate(data)}
      RedisStream.client.xadd(@stream_key, data, maxlen: 1000, approximate: true)
    end
  end
end
