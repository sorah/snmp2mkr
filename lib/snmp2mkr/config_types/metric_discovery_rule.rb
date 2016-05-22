require 'snmp2mkr/config_types/base'
require 'snmp2mkr/config_types/metric_definition_collection'

module Snmp2mkr
  module ConfigTypes
    class MetricDiscoveryRule < Base
      def setup(hash)
        metrics_hash = hash.fetch('metrics')
        if !metrics_hash.kind_of?(Hash) || metrics_hash.any? { |k,v| !k.kind_of?(String) }
          raise TypeError, "#{self.class} metrics must be a Hash<String, Object)>"
        end

        keys_hash = hash.fetch('keys')
        if !keys_hash.kind_of?(Hash) || keys_hash.any? { |k,v| !k.kind_of?(String) }
          raise TypeError, "#{self.class} keys must be a Hash<String, Object>"
        end

        @metrics = MetricDefinitionCollection.new(metrics_hash)
        @keys = keys_hash.map { |k, v| [k, Oid.new(v)] }.to_h
      end

      attr_reader :metrics, :keys

      def collect_children
        [
          *@metrics.values,
          *@keys.values,
        ]
      end
    end
  end
end
