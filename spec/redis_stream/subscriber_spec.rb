require "redis"

RSpec.describe RedisStream::Subscriber do
  let(:stream_key) { "stream_test" }

  before do
    RedisStream.configure do |config|
      config.redis(DummyRedisClient.new)
    end
    allow(described_class).to receive(:sleep)
    allow(described_class).to receive(:log)
  end

  describe ".listen" do
    it "subscribes to the stream" do
      allow(described_class).to receive(:loop).and_yield.twice

      allow(RedisStream.client).to receive(:xreadgroup)
        .and_return([["stream_test", [["message_id", {"name" => "test", "json" => "{}"}]]]])

      described_class.listen(streams: "stream_test") do |stream, message_id, name, json|
        expect(stream).to eq("stream_test")
        expect(message_id).to eq("message_id")
        expect(name).to eq("test")
        expect(json).to eq({})
      end

      described_class.listen(streams: ["stream_test"]) do |stream, message_id, name, json|
        expect(stream).to eq("stream_test")
        expect(message_id).to eq("message_id")
        expect(name).to eq("test")
        expect(json).to eq({})
      end
    end

    def stub_loop_iterations(n)
      allow(described_class).to receive(:loop) do |&block|
        n.times { block.call }
      end
    end

    context "when xreadgroup raises a connection error" do
      it "calls reconnect_with_delay and resumes instead of propagating" do
        stub_loop_iterations(2)
        call_count = 0
        allow(RedisStream.client).to receive(:xreadgroup) do
          call_count += 1
          raise Redis::CannotConnectError, "connection refused" if call_count == 1

          []
        end

        expect(described_class).to receive(:reconnect_with_delay).and_call_original

        expect do
          described_class.listen(streams: stream_key) { |*| }
        end.not_to raise_error
      end
    end

    describe ".reconnect_with_delay" do
      it "returns once ping succeeds" do
        allow(RedisStream.client).to receive(:ping).and_return("PONG")

        expect(described_class).to receive(:sleep).once

        described_class.reconnect_with_delay
      end

      it "keeps retrying with exponential backoff until ping succeeds" do
        ping_calls = 0
        allow(RedisStream.client).to receive(:ping) do
          ping_calls += 1
          raise Redis::CannotConnectError, "still down" if ping_calls < 3

          "PONG"
        end

        sleeps = []
        allow(described_class).to receive(:sleep) { |s| sleeps << s }

        described_class.reconnect_with_delay

        expect(sleeps.size).to eq(3)
        expect(sleeps[1]).to be > sleeps[0]
        expect(sleeps[2]).to be > sleeps[1]
      end

      it "caps backoff at MAX_RECONNECT_BACKOFF" do
        ping_calls = 0
        allow(RedisStream.client).to receive(:ping) do
          ping_calls += 1
          raise Redis::CannotConnectError, "down" if ping_calls < 20

          "PONG"
        end

        sleeps = []
        allow(described_class).to receive(:sleep) { |s| sleeps << s }

        described_class.reconnect_with_delay

        expect(sleeps.last).to eq(RedisStream::Subscriber::MAX_RECONNECT_BACKOFF)
      end
    end

    context "when xreadgroup raises NOGROUP" do
      it "recreates the group and retries without sleeping" do
        stub_loop_iterations(2)
        call_count = 0
        allow(RedisStream.client).to receive(:xreadgroup) do
          call_count += 1
          raise Redis::CommandError, "NOGROUP No such key 'x' or consumer group 'y'" if call_count == 1

          []
        end

        expect(RedisStream.client).to receive(:xgroup).and_call_original
        expect(described_class).not_to receive(:sleep)

        described_class.listen(streams: stream_key) { |*| }
      end
    end

    context "when xreadgroup raises a non-NOGROUP CommandError" do
      it "propagates the error" do
        allow(described_class).to receive(:loop).and_yield
        allow(RedisStream.client).to receive(:xreadgroup)
          .and_raise(Redis::CommandError, "WRONGTYPE Operation against a key holding the wrong kind of value")

        expect do
          described_class.listen(streams: stream_key) { |*| }
        end.to raise_error(Redis::CommandError, /WRONGTYPE/)
      end
    end
  end
end
