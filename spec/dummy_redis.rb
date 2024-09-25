class DummyRedisClient
  def initialize
    @streams = {}
  end

  def xadd(stream, data, approximate: nil, maxlen: nil, nomkstream: nil, id: "*")
    @streams[stream] ||= []
    @streams[stream] << data
  end

  def xreadgroup(group, consumer, streams, condition, count: 1, block: 5000, noack: false)
    @streams[streams] ||= []
    @streams[streams].map.with_index do |data, index|
      [streams, {index => data}]
    end
  end

  def xgroup(*args)
  end

  def xack(stream, group, message_id)
  end
end
