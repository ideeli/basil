require 'singleton'
require 'yaml'

module Basil
  # Configuration is lazy-loaded from ./config/basil.yml. You can create
  # one from the provided example. Note: this location may change in the
  # future.
  class Config
    include Singleton

    def self.method_missing(meth, *args, &block)
      self.instance.send(meth, *args, &block)
    end

    def method_missing(key)
      yaml[key.to_s] if yaml
    end

    def server(delegate)
      unless @server
        case server_type
        when :cli  ; @server = Cli.new(delegate)
        when :skype; @server = Skype.new(delegate)
        else raise 'Invalid or missing server_type. Must be :skype or :cli.'
        end
      end

      @server
    end

    def yaml
      return {} if @hidden

      @yaml ||= YAML::load(File.read('config/basil.yml'))
    end

    # We need to temporarily hide the Config object during evaluation
    # plugins since it can access it and see passwords, etc. Through
    # this approach the only thing that can be seen is the location of
    # the config file which I believe is fairly innocuous.
    def self.hide(&block)
      @hidden = true

      yield

    ensure
      @hidden = false
    end
  end
end
