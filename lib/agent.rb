require 'bundler/setup'
Bundler.require(:default, (ENV['RACK_ENV'] || :development))
require 'json'
require 'agent/configuration'
require 'agent/middleware/chain'
require 'agent/middleware/logging'
require 'agent/relation_proxy'
require 'agent/host'
require 'agent/probe'
require 'agent/work'


module Agent
  class << self
    def runner
      @runner
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration if block_given?
      configuration
    end

    def start
      if dead_runner?
        @runner = Runner.run
      end
    end

    def start!
      if dead_runner?
        @runner = Runner.run!
      end
    end

    def stop
      runner.terminate
    end

    def middleware
      yield configuration.middleware_chain if block_given?
      configuration.middleware_chain
    end

    def running?
      runner.alive?
    end

    def stopped?
      !running?
    end

    def redis(&block)
      @redis ||= ConnectionPool.new(
        size: (configuration.worker_concurrency + 2)) {
          Redis.new configuration.redis_options
        }
      @redis.with(&block)
    end

  private

    def dead_runner?
      if runner && runner.alive?
        false
      else
        true
      end
    end

    def cleanup_dead_runner
      if dead_runner?
        @runner = nil
      end
    end
  end


end

Dir[File.dirname(__FILE__) + '/../plugins/*.rb'].each do |file|
  require file
end

require 'agent/runner'
