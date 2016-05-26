module Snmp2mkr
  module EngineThreads
    class Sender
      def initialize(queue:, logger: Logger.new($stdout))
        @queue = queue
        @logger = logger
        @thread = nil
      end

      attr_reader :queue, :logger, :thread

      def running?
        @thread && @thread.alive?
      end

      def join
        return unless running?
        @thread.join
      end

      def start
        return if running?
        @thread = Thread.new(&method(:main_loop))
      end

      def main_loop
        while job = queue.pop
          process job
        end
      rescue Exception => e
        logger.error "#{e.inspect}\n\t#{e.backtrace.join("\n\t")}"
        sleep 1
        retry
      end

      def process(job)
        logger.debug "processing job #{job.inspect}"
      end
    end
  end
end
