require 'thread'

require 'mackerel/client'

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
    def initialize(config, log_level: 'info', logdev: $stdout)
      @config = config
      @log_level = log_level
      @logdev = logdev

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
      Logger.new(@logdev).tap { |_| _.progname = progname; _.level = @log_level }
    end

    def prepare
      @host_manager = HostManager.new(persist_file: config.persist_file.evaluate)
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
        Snmp2mkr::Discoverer.new(host, host_manager: host_manager, mib: mib).perform!
      end
      logger.info "Initial discovery completed"
    end

    def start(signals: false)
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
        EngineThreads::Sender.new(
          mackerel: Mackerel::Client.new(mackerel_api_key: config.api_key.evaluate),
          host_manager: host_manager,
          queue: @sender_queue,
          logger: new_logger('sender'),
        )
      end

      @worker_threads.each(&:start)
      @sender_threads.each(&:start)

      @timer.start

      handle_signals if signals

      initial_host_update
      load_timer
    end

    def handle_signals
      r,w = IO.pipe
      handler_th = Thread.new(r) { |io|
        io.gets
        stop
        io.gets
        logger.warn "Force shut down"
        exit
      }
      handler = proc do
        w.puts "quit"
      end
      trap(:INT, handler)
      trap(:TERM, handler)
      handler_th.abort_on_exception = true
    end

    def initial_host_update
      logger.debug "Initial host update!"
      host_updater_logger = new_logger('host_updater')
      host_manager.each_host do |host|
        @worker_queue << HostUpdater.new(host, graphs: true, sender_queue: @sender_queue, logger: host_updater_logger)
      end
      i = 0
      until @worker_queue.empty?
        if i == 10
          logger.warn "Initial host update taking time... (#{@worker_queue.size} remaining)"
        elsif i > 10 && (i % 6 == 0)
          logger.warn "Still waiting for initial host update... (#{@worker_queue.size} remaining)"
        elsif i % 2 == 0
          logger.debug "Waiting for initial host update... (#{@worker_queue.size} remaining)"
        end
        i += 1
        sleep 0.5
      end
      if i >= 10
        logger.info "Initial host update completed"
      else
        logger.debug "Initial host update completed"
      end
    end

    def load_timer
      discoverer_logger = new_logger('discoverer')
      host_updater_logger = new_logger('host_updater')
      collector_logger = new_logger('collector')

      host_manager.each_host do |host|
        @timer.add(host.definition.discover_interval) do
          next if @shutdown
          @worker_queue << Discoverer.new(host, host_manager: host_manager, mib: mib, logger: discoverer_logger)
          @worker_queue << HostUpdater.new(host, sender_queue: @sender_queue, logger: host_updater_logger)
        end

        @timer.add(host.definition.interval) do
          next if @shutdown
          @worker_queue << Collector.new(host, metrics_state_holder: metrics_state_holder, host_manager: host_manager, sender_queue: @sender_queue, logger: collector_logger)
        end
      end
    end

    def stop
      logger.info "Shutting down..."
      @shutdown = true
      @timer.stop
      @worker_queue.close
      @sender_queue.close
    end

    def wait
      @timer.join
      [*@worker_threads, *@sender_threads].each(&:join)
    end

    def wait_stop
      logger.debug "Waiting timer to stop"
      @timer.join
      logger.debug "timer stopped"

      logger.debug "Waiting workers to stop"
      @worker_threads.each { |th|
        logger.debug "Waiting #{th.inspect}"
        th.join
      }
      logger.debug "Waiting senders to stop"
      @sender_threads.each { |th|
        logger.debug "Waiting #{th.inspect}"
        th.join
      }
    end

    def run!(signals: true)
      start(signals: signals)
      wait
    end

    def shutdown!
      stop
      wait
    end

    def init
      discovery
      load_timer
    end
  end
end
