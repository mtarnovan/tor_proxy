require 'test_helper'

class TorProxyTest < Minitest::Test
  IP_URI = URI('https://api.ipify.org/?format=text').freeze

  def test_that_it_has_a_version_number
    refute_nil ::TorProxy::VERSION
  end

  def test_proxy
    unproxied_ip = ip
    proxy = TorProxy.instance(logger: Logger.new(nil))
    first_proxy_ip = ip(proxy)
    proxy.stop!

    proxy = TorProxy.instance(logger: Logger.new(nil))
    proxy.request_new_ip
    second_proxy_ip = ip(proxy)

    assert unproxied_ip != first_proxy_ip
    assert unproxied_ip != second_proxy_ip
    assert first_proxy_ip != second_proxy_ip
  end

  private

  def ip(proxy = nil)
    return Net::HTTP.get(IP_URI) if proxy.nil?

    proxy.with_proxy(IP_URI) do |http|
      http.request(Net::HTTP::Get.new(IP_URI)).read_body.chomp
    end
  end
end
