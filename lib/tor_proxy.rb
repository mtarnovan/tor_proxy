require 'net/telnet'
require 'socksify/http'
require 'fileutils'
require 'tmpdir'
require 'logger'

require 'tor_proxy/version'

# rubocop:disable Style/ClassVars
class TorProxy
  private_class_method :new
  @@_singleton_instance = nil
  @@_singleton_mutex = Mutex.new

  TOR_OK = /250 OK\n/

  attr_accessor :logger

  def self.instance(*args)
    return @@_singleton_instance if @@_singleton_instance
    @@_singleton_mutex.synchronize do
      return @@_singleton_instance if @@_singleton_instance
      @@_singleton_instance = new(*args)
    end
    @@_singleton_instance
  end

  def with_proxy(uri)
    raise 'TorProxy was stopped. Call TorProxy.instance again to restart.' if @stopped
    Net::HTTP.SOCKSProxy('127.0.0.1', @tor_socks_port).start(*proxy_config(uri)) { |http| yield http }
  end

  def stop!
    return if @stopped
    remove_control_file
    stop_tor
    remove_data_dir
    @stopped = true
    @@_singleton_instance = nil
  end

  def request_new_ip
    @control.cmd('signal newnym') do |response|
      throw 'Cannot get new IP' unless response.match(TOR_OK)
    end
    @logger.debug 'Tor circuit switch requested'
  end

  private

  def initialize(logger: Logger.new(STDOUT))
    @logger = logger
    @tmp_dir = Dir.mktmpdir('tor_proxy')
    prepare_tor
    start_tor
    initialize_tor_control
    @stopped = false
    at_exit { stop! }
    @logger.debug "Started Tor with control port: #{@tor_control_port}, "\
                  "socks port: #{@tor_socks_port}, data dir: #{@tor_data_dir}"
  end

  def prepare_tor
    random_id = SecureRandom.hex
    @tor_data_dir = File.join(@tmp_dir, random_id)
    @control_port_file = File.join(@tmp_dir, random_id.to_s + '.tmp')
  end

  def initialize_tor_control
    @tor_control_port = control_port_from_file(@control_port_file)
    @authenticated = false
    @control = Net::Telnet.new('Host' => 'localhost', 'Port' => @tor_control_port.to_i, 'Timeout' => 3,
                               'Prompt' => TOR_OK)
    authenticate
    @tor_socks_port = socks_port
  end

  def remove_control_file
    File.delete(@control_port_file) if File.exist?(@control_port_file)
  end

  def remove_data_dir
    FileUtils.remove_entry @tmp_dir
  end

  def stop_tor
    @logger.debug 'Stopping Tor'
    @control.cmd('signal shutdown') do |response|
      throw 'Cannot stop Tor' unless response.match(TOR_OK)
    end
    sleep 0.5
  end

  def start_tor
    tor_start_command = 'tor --ControlPort auto'\
                            ' --SocksPort auto'\
                            " --ControlPortWriteToFile #{@control_port_file}"\
                            ' --RunAsDaemon 1'\
                            " --DataDirectory #{@tor_data_dir}"
    `#{tor_start_command}`
    sleep 0.5
  end

  def socks_port
    @control.cmd('getinfo net/listeners/socks') do |response|
      throw 'Cannot get socks port via Tor control port' unless response.match(TOR_OK)
      return parse_port(response.scan(/"([^"]*)"/).first.first)
    end
  end

  def proxy_config(uri)
    [uri.host,
     uri.port,
     use_ssl: (uri.scheme == 'https'),
     verify_mode: OpenSSL::SSL::VERIFY_NONE]
  end

  def authenticate
    return if @authenticated
    @control.cmd('AUTHENTICATE ""') do |response|
      throw 'Cannot authenticate to Tor' unless response.match(TOR_OK)
    end
    @authenticated = true
  end

  def control_port_from_file(filename)
    parse_port(File.read(filename).split('=').last)
  end

  def parse_port(string)
    string.split(':').last.to_i
  end
end
