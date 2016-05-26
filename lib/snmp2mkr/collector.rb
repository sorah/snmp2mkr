require 'logger'
require 'snmp2mkr/config_types/oid'
require 'snmp2mkr/mib'
require 'snmp2mkr/oid'
require 'snmp2mkr/vhost'

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
      vhosts.each do |vhost|
        vhost.metrics.each do |metric|
          val = metric.evaluate(snmp_values[metric.oid.to_s], state_holder: metrics_state_holder, time: snmp_time)
          sender_queue << [:metric, host.name, vhost.name, metric.name, val]
        end
      end
      # FIXME: sender_queue
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
