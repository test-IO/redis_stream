# frozen_string_literal: true

RSpec.describe RedisStream do
  it "has a version number" do
    expect(RedisStream::VERSION).not_to be nil
  end

  describe ".configure" do
    it "yields the configuration" do
      RedisStream.configure do |config|
        expect(config).to be_instance_of(RedisStream::Configuration)
      end
    end

    it "allow setting the client" do
      RedisStream.configure do |config|
        config.redis(DummyRedisClient.new)
      end

      expect(RedisStream.client).to be_instance_of(DummyRedisClient)
    end
  end
end
