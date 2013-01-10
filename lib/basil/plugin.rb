module Basil
  # The plugin class is used to encapsulate triggered actions. Plugin
  # writers must use respond_to or watch_for to create an instance of
  # Plugin with a singleton execute method.
  class Plugin
    include Utils

    private_class_method :new

    # Create an instance of Plugin which will look for regex only in
    # messages that are to basil.
    def self.respond_to(regex, &block)
      new(regex, &block).tap { |p| responders << p }
    end

    # Create an instance of Plugin which will look for regex in any
    # messages sent in the chat.
    def self.watch_for(regex, &block)
      new(regex, &block).tap { |p| watchers << p }
    end

    # Create an instance of Plugin which will look for regex in the
    # subject of any emails basil receives.
    def self.check_email(regex, &block)
      new(regex, &block).tap { |p| email_checkers << p }
    end

    def self.responders
      @responders ||= []
    end

    def self.watchers
      @watchers ||= []
    end

    def self.email_checkers
      @email_checkers ||= []
    end

    def self.load!
      dir = Config.plugins_directory

      if Dir.exists?(dir)
        Dir.glob("#{dir}/*").sort.each do |f|
          begin load(f)
          rescue Exception => ex
            logger.warn ex
            next
          end
        end
      end
    end

    def self.logger
      @logger ||= Loggers['plugins']
    end

    attr_reader :regex
    attr_accessor :description

    def initialize(regex, &block)
      @regex = regex.is_a?(String) ? Regexp.new("^#{regex}$") : regex

      define_singleton_method(:execute, &block)
    end

    # Set the appropriate instance variables for an execution context.
    def set_context(msg, match_data)
      @msg = msg
      @match_data = match_data
    end

    def to_s
      "#<Plugin regex: #{regex.inspect}, description: #{description.inspect} >"
    end

    def logger
      self.class.logger
    end
  end
end
