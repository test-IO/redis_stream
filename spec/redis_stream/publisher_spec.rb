RSpec.describe RedisStream::Publisher do
  let(:stream_key) { "test" }
  let(:publisher) { described_class.new(stream_key) }

  before do
    RedisStream.configure do |config|
      config.redis(DummyRedisClient.new)
    end
  end

  describe "#publish" do
    it "publishes the message to the stream" do
      publisher.publish("test", {name: "test"})
    end
  end
end
