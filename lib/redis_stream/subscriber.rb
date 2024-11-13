# frozen_string_literal: true

module RedisStream
  class Subscriber
    def self.listen(streams:, group: nil, consumer: nil, &block)
      group ||= RedisStream.config.group_id
      consumer ||= RedisStream.config.consumer_id
      streams = Array(streams)

      return unless streams.any?

      streams.each do |stream_key|
        create_group(stream_key, group)
      end

      loop do
        # listen for up to 10 messages forever
        ids = Array.new(streams.length, ">")
        messages = RedisStream.client.xreadgroup(group, consumer, streams, ids, count: 1, block: 0, noack: true)

        messages.each do |stream, stream_messages|
          stream_messages.each do |message_id, message_hash|
            yield(stream, message_id, message_hash["name"], JSON.parse(message_hash["json"]))
          end
        end
      end
    end

    def self.create_group(stream_key, group_name)
      RedisStream.client.xgroup(:create, stream_key, group_name, "$", mkstream: true)
    rescue Redis::CommandError => e
      raise e unless e.message.include?("BUSYGROUP") # the group already existing is fine
    end
  end
end
