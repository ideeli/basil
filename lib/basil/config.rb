require 'yaml'

module Basil
  module Config
    DEFAULTS = {
      'me'                => 'basil',
      'server_class'      => Skype,
      'plugins_directory' => File.join(Dir.pwd, 'plugins'),
      'pstore_file'       => File.join(Dir.pwd, 'basil.pstore'),
      'config_file'       => File.join(Dir.pwd, 'config', 'basil.yml'),
      'lock_file'         => File.join('', 'tmp', 'basil.lock'),
      'email'             => {},
      'extras'            => {}
    }

    class << self
      attr_writer(*DEFAULTS.keys)

      def method_missing(key, *)
        attribute(key) || extras["#{key}"]
      end

      def load!
        return unless config_file && File.exists?(config_file)

        yaml = YAML::load(File.read(config_file))

        DEFAULTS.keys.each do |key|
          if yaml.has_key?(key)
            value = yaml.delete(key)
            send("#{key}=", value)
          end
        end

        self.extras = yaml

      rescue => ex
        Basil.logger.warn "Error loading #{config_file}:"
        Basil.logger.warn ex
      end

      attr_writer :server

      def server
        @server ||= server_class.new
      end

      def check_email?
        !( server.is_a?(Cli) || email.empty? )
      end

      private

      def attribute(key)
        ivar = :"@#{key}"

        if instance_variables.include?(ivar)
          instance_variable_get(ivar)
        else
          DEFAULTS["#{key}"]
        end
      end

      def hide(&block)
        current = extras
        self.extras = nil

        yield

      ensure
        self.extras = current
      end

    end
  end
end
