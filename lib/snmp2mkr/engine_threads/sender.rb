require 'mackerel/client'
require 'snmp2mkr/mackerel_ext'
require 'snmp2mkr/send_requests/host_information'
require 'snmp2mkr/send_requests/metrics'
require 'snmp2mkr/send_requests/graphs'

module Snmp2mkr
  module EngineThreads
    class Sender
      def initialize(mackerel:, host_manager:, queue:, logger: Logger.new($stdout))
        @mackerel = mackerel
        @host_manager = host_manager
        @queue = queue
        @logger = logger
        @thread = nil
      end

      attr_reader :mackerel, :host_manager, :queue, :logger, :thread

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
        logger.debug "sending #{job.inspect}"

        case job
        when Snmp2mkr::SendRequests::Graphs
          add_graphs job
        when Snmp2mkr::SendRequests::Metrics
          send_metrics job
        when Snmp2mkr::SendRequests::HostInformation
          update_host job
        else
          raise TypeError, "Invalid send_request: #{job.class}"
        end
      end

      def add_graphs(job)
        logger.info "Define graphs on Mackerel: #{job.inspect}"
        resp = mackerel.define_graphs(job.graphdefs)
        logger.debug "Mackerel response (#{job.inspect}): #{resp.inspect}"
      end

      def update_host(job)
        host_id = get_host_id(job.vhost)

        host = {
          name: job.vhost.name,
          meta: job.meta,
          interfaces: job.interfaces,
        }
        logger.debug "Update host (#{job.vhost.name}, #{host_id}): #{host.to_json}"
        resp = mackerel.put_host(host_id, host)
        logger.debug "Mackerel response (update_host #{host_id.inspect}): #{resp.inspect}"
      end

      def send_metrics(job)
        metric_values = job.metric_values.map do |mv|
          {
            hostId: get_host_id(mv[:vhost]),
            name: mv[:name],
            time: mv[:time].to_i,
            value: mv[:value]
          }
        end

        logger.debug "Posting metrics #{job.inspect}: #{metric_values.inspect}"
        resp = mackerel.post_metrics(metric_values)
        logger.debug "Mackerel response (#{job.inspect}): #{resp.inspect}"
      end

      def get_host_id(vhost)
        host_manager.set_mackerel_host_id_safe(vhost) do
          logger.debug "Registering #{vhost.name.inspect}"
          mackerel.post_host(name: vhost.name, meta: {})['id'].tap do |host_id|
            logger.info "Registered #{vhost.name.inspect} as #{host_id.inspect}"
          end
        end
      end
    end
  end
end
