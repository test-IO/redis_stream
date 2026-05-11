# frozen_string_literal: true

module RedisStream
  class Subscriber
    INITIAL_BACKOFF = 0.5
    MAX_BACKOFF = 30.0

    class << self
      def listen(streams:, group: RedisStream.config.group_id, consumer: RedisStream.config.consumer_id)
        return unless (streams = Array(streams)).any?

        loop do
          RedisStream.client.xreadgroup(
            group,                              # consumer group name (must exist; XGROUP CREATE handles that)
            consumer,                           # this consumer's name within the group; identifies who owns delivered messages
            streams,                            # stream keys to read from
            Array.new(streams.length, ">"),     # per-stream start ID; ">" means "only new messages, never redelivered"
            count: 1,                           # max messages returned per stream per call
            block: 0,                           # block forever waiting for new messages (ms; 0 = no timeout)
            noack: true                         # skip the pending-entries list — at-most-once delivery, no XACK/XCLAIM recovery
          ).each do |stream, stream_messages|
            stream_messages.each do |message_id, message_hash|
              yield(stream, message_id, message_hash["name"], JSON.parse(message_hash["json"]))
            end
          end
        rescue Redis::BaseConnectionError => e
          log("Disconnected from Redis (#{e.class}: #{e.message})")

          reconnect_with_delay
        rescue Redis::CommandError => e
          raise unless e.message.include?("NOGROUP")

          ensure_groups_in_place!(streams, group)
        end
      end

      def reconnect_with_delay
        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        backoff    = INITIAL_BACKOFF
        attempt    = 0

        loop do
          attempt += 1

          log("Reconnect attempt ##{attempt}: sleeping #{backoff}s before ping")

          sleep(backoff)

          begin
            RedisStream.client.ping
            downtime = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at

            log("Reconnected to Redis after #{attempt} attempt(s); downtime #{format_duration(downtime)}")

            return
          rescue Redis::BaseConnectionError => e
            log("Reconnect attempt ##{attempt} failed: #{e.class}: #{e.message}")

            backoff = [backoff * 2, MAX_BACKOFF].min
          end
        end
      end

      def ensure_groups_in_place!(streams, group)
        streams.each do |stream_key|
          log("Creating consumer group #{group.inspect} on stream #{stream_key.inspect}")

          RedisStream.client.xgroup(:create, stream_key, group, "$", mkstream: true)
        rescue Redis::CommandError => e
          raise unless e.message.include?("BUSYGROUP")

          log("Consumer group #{group.inspect} on stream #{stream_key.inspect} already exists")
        end
      end

      def format_duration(seconds)
        return format("%.2fs", seconds) if seconds < 60

        minutes, secs = seconds.divmod(60)
        return format("%dm %ds", minutes, secs) if minutes < 60

        hours, mins = minutes.divmod(60)
        format("%dh %dm %ds", hours, mins, secs)
      end

      def log(message)
        warn("[redis_stream] #{message}")
      end
    end
  end
end
