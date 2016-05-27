require 'snmp2mkr/config_types/base'

module Snmp2mkr
  module ConfigTypes
    class GraphMetric < Base
      def setup(kv)
        raise TypeError, "#{self.class} must be given an Array (BUG?)" unless kv.kind_of?(Array) && kv.size == 2
        k, v = kv

        raise ArgumentError, "#{self.class} key must be String" unless k.kind_of?(String)
        raise ArgumentError, "#{self.class} value must be Hash" unless v.nil? || v.kind_of?(Hash)
        v ||= {}

        @name = k

        @display_name = v['display_name']
        raise TypeError, "#{self.class} display_name must be a String" if @display_name && !@display_name.kind_of?(String)

        @stacked = !!v.fetch('stacked', false)
      end

      def for_mackerel
        {
          name: name,
          isStacked: stacked?,
        }.tap do |h|
          h[:displayName] = display_name if display_name
        end
      end

      def stacked?
        @stacked
      end

      attr_reader :name, :display_name
    end
  end
end
