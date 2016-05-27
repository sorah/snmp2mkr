require 'logger'
require 'snmp2mkr/config_types/oid'
require 'snmp2mkr/mib'
require 'snmp2mkr/oid'
require 'snmp2mkr/vhost'
require 'snmp2mkr/send_requests/host_information'
require 'snmp2mkr/send_requests/graphs'

module Snmp2mkr
  class HostUpdater
    InterfaceInfo = Struct.new(:match_data, :values) do
      def match?(other)
        match_data.any?{ |k,v| other[k].to_s == v.to_s }
      end
    end

    def initialize(host, sender_queue: nil, logger: Logger.new(File::NULL), mib: Mib.default, graphs: false)
      @host = host
      @sender_queue = sender_queue
      @logger = logger
      @mib = mib
      @send_graphs = graphs
    end

    def inspect
      "#<#{self.class}:#{'%x' % __id__}, #{host.name.inspect}>"
    end

    attr_reader :host, :sender_queue, :logger, :mib

    def send_graphs?
      !!@send_graphs
    end

    def perform!
      if send_graphs?
        SendRequests::Graphs.new(graphdefs).tap do |req|
          sender_queue << req
        end
      end

      SendRequests::HostInformation.new(host, meta: meta, interfaces: interfaces).tap do |req|
        sender_queue << req
      end
    rescue ClosedQueueError => e
      logger.warn "#{e.inspect} (during shutdown?)"
    end

    def graphdefs
      @graphdefs ||= host.graphs.each_value.map(&:for_mackerel)
    end

    def meta
      @meta ||= host.meta_definitions.inject({}) do |meta, rule|
        rule_keys = rule.keys.map { |k, confoid| [k, Snmp2mkr::Oid.new(confoid.evaluate, mib: mib)] }
        keys = rule_keys.map { |k, oid| [k, snmp_values[oid.to_s].value.to_s] }.to_h

        meta.merge(rule.bind_context(keys).values.map { |k,v| [k,v.evaluate] }.to_h)
      end
    end

    def interfaces
      @interfaces ||= host.interface_definitions.each_with_object([]) do |rule, ifaces|
        rule_keys = rule.keys.map { |k, confoid| [k, Snmp2mkr::Oid.new(confoid.evaluate, mib: mib)] }
        primary_oid = rule_keys.first.last.to_s

        snmp_trees[primary_oid].flat_map do |index_vb|
          index = index_vb.oid.index_of(primary_oid)
          keys = rule_keys.map do |k, oid|
            [k, snmp_trees[oid.to_s].find{ |vb| vb.oid.index_of(oid) == index }.value.to_s]
          end.to_h
          keys['index'] = index

          bind_rule = rule.bind_context(keys)
          match_data = bind_rule.match.map{ |k, v|  [k, v.evaluate] }.to_h

          iface = ifaces.find { |_| _.match?(match_data) }
          unless iface
            iface = InterfaceInfo.new({}, {})
            ifaces.push iface
          end
          iface.match_data.merge!(match_data)
          bind_rule.values.each do |k, v|
            iface.values[k] = v.evaluate(previous: iface.values[k])
          end
        end
      end.map(&:values)
    end

    def snmp_values
      @snmp_values ||= host.snmp do |snmp|
        oids = [*host.meta_definitions].
          compact.
          flat_map { |_| _.keys.values.map(&:evaluate) }.
          uniq.
          map { |_| Snmp2mkr::Oid.new(_, mib: mib) }

        snmp.get(oids).map do |vb|
          [vb.oid.to_s, vb]
        end.to_h
      end
    end

    def snmp_trees
      @snmp_trees ||= host.snmp do |snmp|
        oids = [*host.interface_definitions].
          compact.
          flat_map { |_| _.keys.values.map(&:evaluate) }.
          uniq.
          map { |_| Snmp2mkr::Oid.new(_, mib: mib) }.
          uniq.
          sort_by { |_| -_.to_a.size }

        oids.map do |oid|
          [oid.to_s, snmp.subtree(oid).to_a]
        end.to_h
      end
    end
  end
end
