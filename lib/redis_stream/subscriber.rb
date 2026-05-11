# frozen_string_literal: true

module RedisStream
  class Subscriber
    INITIAL_BACKOFF = 0.5
    MAX_BACKOFF = 30.0

    def self.listen(streams:, group: nil, consumer: nil)
      group ||= RedisStream.config.group_id
      consumer ||= RedisStream.config.consumer_id
      streams = Array(streams)

      return unless streams.any?

      ensure_groups(streams, group)

      loop do
        ids = Array.new(streams.length, ">")
        messages = RedisStream.client.xreadgroup(group, consumer, streams, ids, count: 1, block: 0, noack: true)

        messages.each do |stream, stream_messages|
          stream_messages.each do |message_id, message_hash|
            yield(stream, message_id, message_hash["name"], JSON.parse(message_hash["json"]))
          end
        end
      rescue Redis::BaseConnectionError => e
        log("disconnected from redis (#{e.class}: #{e.message})")
        wait_for_reconnect
      rescue Redis::CommandError => e
        raise unless e.message.include?("NOGROUP")

        log("NOGROUP detected; recreating consumer groups")
        ensure_groups(streams, group)
      end
    end

    def self.wait_for_reconnect
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      backoff = INITIAL_BACKOFF
      attempt = 0
      loop do
        attempt += 1
        log("reconnect attempt ##{attempt}: sleeping #{backoff}s before ping")
        sleep(backoff)
        begin
          RedisStream.client.ping
          downtime = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
          log("reconnected to redis after #{attempt} attempt(s); downtime #{format_duration(downtime)}")
          return
        rescue Redis::BaseConnectionError => e
          log("reconnect attempt ##{attempt} failed: #{e.class}: #{e.message}")
          backoff = [backoff * 2, MAX_BACKOFF].min
        end
      end
    end

    def self.format_duration(seconds)
      return format("%.2fs", seconds) if seconds < 60

      minutes, secs = seconds.divmod(60)
      return format("%dm %ds", minutes, secs) if minutes < 60

      hours, mins = minutes.divmod(60)
      format("%dh %dm %ds", hours, mins, secs)
    end

    def self.ensure_groups(streams, group)
      streams.each { |stream_key| create_group(stream_key, group) }
    end

    def self.create_group(stream_key, group_name)
      log("creating consumer group #{group_name.inspect} on stream #{stream_key.inspect}")
      RedisStream.client.xgroup(:create, stream_key, group_name, "$", mkstream: true)
    rescue Redis::CommandError => e
      raise unless e.message.include?("BUSYGROUP")

      log("consumer group #{group_name.inspect} on stream #{stream_key.inspect} already exists")
    end

    def self.log(message)
      warn("[redis_stream] #{message}")
    end
  end
end
