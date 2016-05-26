require 'thread'

require 'snmp2mkr/host_manager'
require 'snmp2mkr/metrics_state_holder'
require 'snmp2mkr/mib'

require 'snmp2mkr/engine_threads/timer'
require 'snmp2mkr/engine_threads/sender'
require 'snmp2mkr/engine_threads/worker'

require 'snmp2mkr/discoverer'
require 'snmp2mkr/collector'
require 'snmp2mkr/host_updater'

module Snmp2mkr
  class Engine
    def initialize(config)
      @config = config
      @shutdown = nil
      @logger = new_logger('engine')

      @mib = Mib.new(
        load_path: config.mib_load_path,
        modules: config.mib_no_default_modules ? config.mib_modules : [*Mib::DEFAULT_MODULES, *config.mib_modules],
      )

      @host_manager = nil
      @metrics_state_holder = nil

      @worker_queue = nil
      @sender_queue = nil

      @timer = nil
      @worker_threads = nil
      @sender_threads = nil
    end

    attr_reader :logger, :config, :host_manager, :metrics_state_holder, :mib

    def new_logger(progname)
      Logger.new($stdout).tap { |_| _.progname = progname; _.level = Logger::DEBUG }
    end

    def prepare
      @host_manager = HostManager.new
      @metrics_state_holder = MetricsStateHolder.new

      load_hosts
      initial_discover
    end

    def load_hosts
      config.hosts.evaluate.each do |name, hostdef|
        host = Snmp2mkr::Host.new(hostdef, template_collection: config.templates)
        logger.info "Loaded host: #{host.inspect}"
        host_manager.add_host host
      end
    end

    def initial_discover
      host_manager.each_host do |host|
        logger.info "Initial discovery of #{host.inspect}"
        Snmp2mkr::Discoverer.new(host, host_manager: host_manager).perform!
      end
      logger.info "Initial discovery completed"
    end

    def start
      raise 'already ran' unless @shutdown.nil?
      @shutdown = false

      prepare

      @worker_queue = Queue.new
      @sender_queue = Queue.new

      @timer = EngineThreads::Timer.new(logger: new_logger('timer'))

      @worker_threads = 2.times.map do
        EngineThreads::Worker.new(queue: @worker_queue, logger: new_logger('worker'))
      end

      @sender_threads = 2.times.map do
        EngineThreads::Sender.new(queue: @sender_queue, logger: new_logger('sender'))
      end

      @worker_threads.each(&:start)
      @sender_threads.each(&:start)

      @timer.start

      load_timer
    end

    def load_timer
      discoverer_logger = new_logger('discoverer')
      host_updater_logger = new_logger('host_updater')
      collector_logger = new_logger('collector')

      host_manager.each_host do |host|
        @timer.add(host.definition.discover_interval) do
          @worker_queue << Discoverer.new(host, host_manager: host_manager,  logger: discoverer_logger)
          @worker_queue << HostUpdater.new(host, sender_queue: @sender_queue, logger: host_updater_logger)
        end

        @timer.add(host.definition.interval) do
          @worker_queue << Collector.new(host, metrics_state_holder: metrics_state_holder, host_manager: host_manager, sender_queue: @sender_queue, logger: collector_logger)
        end
      end
    end

    def stop
    end

    def run!
      start
      sleep # FIXME
    end

    def shutdown!
    end

    def init
      discovery
      load_timer
    end
  end
end
