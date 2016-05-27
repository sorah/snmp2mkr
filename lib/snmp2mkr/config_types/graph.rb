require 'snmp2mkr/config_types/base'
require 'snmp2mkr/config_types/graph_metric'

module Snmp2mkr
  module ConfigTypes
    class Graph < Base
      def setup(kv)
        raise TypeError, "#{self.class} must be given an Array (BUG?)" unless kv.kind_of?(Array) && kv.size == 2
        k, v = kv

        raise ArgumentError, "#{self.class} key must be String" unless k.kind_of?(String)
        raise ArgumentError, "#{self.class} value must be Hash" unless v.kind_of?(Hash)

        @name = k

        @display_name = v['display_name']
        raise TypeError, "#{self.class} display_name must be a String" if @display_name && !@display_name.kind_of?(String)

        @unit = v['unit']
        raise TypeError, "#{self.class} unit must be a String" if @unit && !@unit.kind_of?(String)

        metrics = v['metrics']
        if !metrics.kind_of?(Hash) || metrics.any?{ |k,v| !k.kind_of?(String) }
          raise TypeError, "#{self.class} metrics must be a Hash<String, Object>" 
        end
        @metrics = metrics.map { |k, v| [k, GraphMetric.new([k,v])] }.to_h
      end

      def for_mackerel
        {
          name: name,
          metrics: metrics.each_value.map(&:for_mackerel),
        }.tap do |h|
          h[:displayName] = display_name if display_name
          h[:unit] = unit if unit
        end
      end

      attr_reader :name, :display_name, :unit, :metrics

      def collect_children
        @metrics.values
      end
    end
  end
end
