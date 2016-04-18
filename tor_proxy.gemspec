# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tor_proxy/version'

Gem::Specification.new do |spec|
  spec.name          = 'tor_proxy'
  spec.version       = TorProxy::VERSION
  spec.authors       = ["Mihai Târnovan"]
  spec.email         = ['mihai.tarnovan@cubus.ro']

  spec.summary       = 'Facilitates using Tor as a proxy for HTTP requests using net/http'
  spec.description   = 'Facilitates using Tor as a proxy for HTTP requests using net/http'
  spec.homepage      = 'https://github.com/mtarnovan/tor_proxy'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'

  spec.add_runtime_dependency 'socksify'
  spec.add_runtime_dependency 'net-telnet'
end
