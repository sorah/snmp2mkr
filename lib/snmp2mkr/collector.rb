require 'logger'
require 'snmp2mkr/config_types/oid'
require 'snmp2mkr/mib'
require 'snmp2mkr/oid'
require 'snmp2mkr/vhost'
require 'snmp2mkr/send_requests/metrics'

module Snmp2mkr
  class Collector
    def initialize(host, metrics_state_holder:, host_manager:, sender_queue: nil, logger: Logger.new(File::NULL), mib: Mib.default)
      @host = host
      @metrics_state_holder = metrics_state_holder
      @host_manager = host_manager
      @sender_queue = sender_queue
      @logger = logger
      @mib = mib
    end

    def inspect
      "#<#{self.class}:#{'%x' % __id__}, #{host.name.inspect}>"
    end

    attr_reader :host, :metrics_state_holder, :host_manager, :sender_queue, :logger, :mib

    def vhosts
      host_manager.vhosts(host)
    end

    def perform!
      metric_values = vhosts.flat_map do |vhost|
        vhost.metrics.map do |metric|
          val = metric.evaluate(snmp_values[metric.oid.to_s], state_holder: metrics_state_holder, time: snmp_time)
          next if val.nil?
          {vhost: vhost, host: host, name: metric.safe_name, value: val, time: snmp_time}
        end.compact
      end
      SendRequests::Metrics.new(metric_values).tap do |req|
        sender_queue << req
      end
    end

    def snmp_time
      snmp_values; @snmp_time
    end

    def snmp_values
      @snmp_values ||= begin
        @snmp_time = Time.now
        host.snmp do |snmp|
          oids = vhosts.flat_map(&:metrics).map(&:oid).map(&:to_s).uniq
          snmp.get(oids).map do |vb|
            [vb.oid.to_s, vb]
          end.to_h
        end
      end
    end
  end
end
