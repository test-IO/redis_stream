# frozen_string_literal: true

require_relative "redis_stream/version"
require_relative "redis_stream/configuration"
require_relative "redis_stream/publisher"
require_relative "redis_stream/subscriber"

module RedisStream
  class Error < StandardError; end

  def self.configure
    yield config if block_given?
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.config
    configuration
  end

  def self.client
    config.client
  end

  def self.default_publisher
    @default_publisher ||= Publisher.new(config.stream_key)
  end
end
