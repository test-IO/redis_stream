# RedisStream

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/redis_stream`. To experiment with that code, run `bin/console` for an interactive prompt.

## Installation

Install the gem and add to the application's Gemfile by executing:
```ruby
  # Gemfile
  $ gem "redis_stream", git: "https://github.com/test-IO/redis_stream"
```

## Usage

Initialize the gem with the Redis client you want to use in you `config/initializers/

```ruby
RedisStream.configure do |config|
  config.redis(Redis.new(url: "redis://localhost:6379/0"))
  config.group("group_name")
  config.consumer("consumer_name")
  config.stream("stream_name")
end
```
### Subscribe
To subscribe you will always need to provide the name of the stream you want to listen to, you can also provide an array of stream.

```ruby
loop do
  RedisStream::Subscriber.listen(streams: ["stream_name"]) do |stream, message_id, message_name, payload|
    puts "Received #{message_name}, payload: #{payload} [#{stream} -> #{message_id}]"
  end
end
```

### Publish

You have two option either you use the default publisher if you do not need to change the stream.

```ruby
RedisStream.default_publisher.publish("event_name", { text: "Hello World" })
```

or if you need to publish to a different stream

```ruby
RedisStream::Publisher.new("other_stream").publish("event_name", {text: "Hello world2" })
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Testing

The gem is using rspec to run the test

```
rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/redis_stream. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/redis_stream/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RedisStream project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/redis_stream/blob/main/CODE_OF_CONDUCT.md).
