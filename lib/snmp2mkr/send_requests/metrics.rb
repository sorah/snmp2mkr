require 'snmp2mkr/vhost'

module Snmp2mkr
  module SendRequests
    class Metrics
      def initialize(metric_values)
        metric_values.each do |m|
          if !m.kind_of?(Hash) || !m[:vhost].kind_of?(Vhost) || !m[:value] || !m[:name] || !m[:time]
            raise TypeError, "invalid metric_values #{m.inspect}"
          end
        end
        @metric_values = metric_values
      end

      def inspect
        "#<#{self.class}:#{'%x' % __id__}: #{metric_values.size} metric_values>"
      end

      attr_reader :metric_values
    end
  end
end
