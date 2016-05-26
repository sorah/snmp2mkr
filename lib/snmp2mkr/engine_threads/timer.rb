module Snmp2mkr
  module EngineThreads
    class Timer
      Entry = Struct.new(:interval, :hook, :last)

      def initialize(logger: Logger.new($stdout))
        @shutdown = false
        @entries = []
        @logger = logger
        @thread = nil
      end

      attr_reader :entries, :logger, :thread

      def add(interval, &hook)
        entry = Entry.new(interval, hook, now - interval + rand(15))
        logger.info "Added timer #{entry.inspect}"
        @entries << entry
      end

      def running?
        @thread && @thread.alive?
      end

      def join
        return unless running?
        @thread.join
      end

      def start
        return if running?
        @shutdown = false
        @thread = Thread.new(&method(:main_loop))
      end

      def stop
        return unless running?
        @shutdown = true
      end

      def main_loop
        logger.info "timer started"
        loop do
          break if @shutdown
          tick
          sleep 1
        end
        logger.info "timer shutdown"
      rescue Exception => e
        logger.error "#{e.inspect}\n\t#{e.backtrace.join("\n\t")}"
        retry
      end

      def tick
        t = now
        @entries.each do |entry|
          kick(entry) if (now - entry.last) > entry.interval
        end
      end

      def kick(entry)
        logger.debug "timer kick entry #{entry.inspect}"
        entry.last = now
        Thread.new do
          begin
            entry.hook.call
          rescue Exception => e
            logger.error "#{e.inspect}\n\t#{e.backtrace.join("\n\t")}"
          end
        end
      end

      private

      def now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
