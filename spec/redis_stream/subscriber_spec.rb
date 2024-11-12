RSpec.describe RedisStream::Subscriber do
  let(:stream_key) { "test" }

  before do
    RedisStream.configure do |config|
      config.redis(DummyRedisClient.new)
    end
  end

  describe ".listen" do
    it "subscribes to the stream" do
      allow(described_class).to receive(:loop).and_yield.twice

      allow(RedisStream.client).to receive(:xreadgroup).and_return([
        ["stream_test", [["message_id", {"name" => "test", "json" => "{}"}]]]
      ])

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
  end
end
