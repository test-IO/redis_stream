# frozen_string_literal: true

module RedisStream
  class Subscriber
    def self.listen(group: nil, consumer: nil, streams:, &block)
      group = group || RedisStream.config.group
      consumer = consumer || RedisStream.config.consumer
      streams = Array(streams)

      return unless streams.any?

      streams.each do |stream_key|
        create_group(stream_key, group)
      end

      # listen for up to 10 messages forever
      messages = RedisStream.client.xreadgroup(group, consumer, streams, ">", count: 1, block: 0)

      messages.each do |stream, stream_messages|
        stream_messages.each do |message_id, message_hash|
          yield(stream, message_id, message_hash["name"], JSON.parse(message_hash["json"]))
        end
      end
    end

    def self.create_group(stream_key, group_name)
      begin
        RedisStream.client.xgroup(:create, stream_key, group_name, '$', mkstream: true)
      rescue Redis::CommandError => e
        raise e unless e.message.include?('BUSYGROUP') # the group already existing is fine
      end
    end
  end
end
