# TorProxy

## Requirements

This gem needs the `tor` executable in $PATH. (`brew install tor` etc.)

## Usage

```ruby
require 'tor_proxy'
uri = URI('https://api.ipify.org/?format=text')

proxy = TorProxy.instance(logger: Logger.new(STDOUT))
proxy.with_proxy(uri) { |proxy| proxy.request(Net::HTTP::Get.new(uri)).read_body.chomp }
# => some IP (of the current Tor exit node)
proxy.request_new_ip
proxy.with_proxy(uri) { |proxy| proxy.request(Net::HTTP::Get.new(uri)).read_body.chomp }
# => some other IP  (of the current Tor exit node)
proxy.stop!
```

## Notes

When the singleton instance is initialized, Tor will be started with a random SOCKS port, a random control port and a temp dir is used as its data dir (removed automatically when you call `stop!`).

The `Kernel#at_exit` hook is used to call `stop!` (unless it was previously invoked manually).

SSL connections are *not* verified (`OpenSSL::SSL::VERIFY_NONE`)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
