RSpec.describe RedisStream::Subscriber do
  let(:stream_key) { "test" }


  before do
    RedisStream.configure do |config|
      config.redis(DummyRedisClient.new)
    end
  end

  describe ".listen" do
    it "subscribes to the stream" do
      described_class.listen(streams: "stream_test") do |message|
        expect(message).to eq("test")
      end

      described_class.listen(streams: ["stream_test"]) do |message|
        expect(message).to eq("test")
      end
    end
  end
end
