require 'snmp2mkr/config_types/base'
require 'snmp2mkr/config_types/template_string'
require 'snmp2mkr/config_types/metric_definition_collection'
require 'snmp2mkr/config_types/oid'

module Snmp2mkr
  module ConfigTypes
    class VhostDiscoveryRule < Base
      def setup(hash)
        metrics_hash = hash.fetch('metrics')
        if !metrics_hash.kind_of?(Hash) || metrics_hash.any? { |k,v| !k.kind_of?(String) }
          raise TypeError, "#{self.class} metrics must be a Hash<String, Object)>"
        end

        keys_hash = hash.fetch('keys')
        if !keys_hash.kind_of?(Hash) || keys_hash.any? { |k,v| !k.kind_of?(String) }
          raise TypeError, "#{self.class} keys must be a Hash<String, Object>"
        end

        roles = hash.fetch('roles', [])
        if !roles.kind_of?(Array) || roles.any? { |k,v| !k.kind_of?(String) }
          raise TypeError, "#{self.class} roles must be a Array<String>"
        end

        @keys = keys_hash.map { |k, v| [k, Oid.new(v)] }.to_h
        @name = TemplateString.new(hash.fetch('name'))
        @roles = roles.map { |v| TemplateString.new(v) }
        @metrics = MetricDefinitionCollection.new(metrics_hash)
      end

      attr_reader :metrics, :keys, :roles, :name

      def collect_children
        [
          *@metrics,
          *@keys.values,
          *@roles,
          @name,
        ]
      end
    end
  end
end
