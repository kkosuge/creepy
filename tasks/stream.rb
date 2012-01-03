# -*- coding: utf-8 -*-

module Creepy
  class Stream < Base
    Tasks.add_task :stream, self

    class_option :daemon, aliases: '-d', default: false, type: :boolean

    def setup
      config = Creepy.reload_config!

      @client = UserStream.client(config)

      @hooks = []
      if config.stream && config.stream.hooks
        config.stream.hooks.each do |hook_name, params|
          hook = Hooks.hooks[hook_name.to_sym]
          @hooks << hook.new(params) if hook
        end
      end
    end
    alias_method :reload, :setup

    def trap
      Signal.trap(:HUP) do
        reload
      end
    end

    def boot
      Process.daemon if options.daemon?
      loop do
        @client.user &method(:process)
      end
    end

    private
    def process(status)
      @hooks.each {|h| h.call status}
    end

    Dir[File.dirname(__FILE__) + '/stream/*.rb'].each {|f| require f}
  end
end