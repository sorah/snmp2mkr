require 'snmp2mkr/config_types/base'

require 'snmp2mkr/config_types/templates_list'
require 'snmp2mkr/config_types/metric_definition_collection'
require 'snmp2mkr/config_types/meta_definition'
require 'snmp2mkr/config_types/interfaces_definition'
require 'snmp2mkr/config_types/metric_discovery_rule_collection'
require 'snmp2mkr/config_types/vhost_discovery_rule_collection'

module Snmp2mkr
  module ConfigTypes
    class Template < Base
      def setup(kv)
        raise TypeError, "#{self.class} must be given an Array (BUG?)" unless kv.kind_of?(Array) && kv.size == 2
        k, hash = kv
        @name = k
        raise TypeError, "#{self.class} must be given a Hash" unless hash.kind_of?(Hash)

        @templates = hash.key?('templates') ? TemplatesList.new(hash['templates']) : nil
        @metrics = hash.key?('metrics') ? MetricDefinitionCollection.new(hash['metrics']) : nil
        @meta = hash.key?('meta') ? MetaDefinition.new(hash['meta']) : nil
        @interfaces = hash.key?('interfaces') ? InterfacesDefinition.new(hash['interfaces']) : nil
        @metric_discoveries = hash.key?('metric_discoveries') ? MetricDiscoveryRuleCollection.new(hash['metric_discoveries']) : nil
        @vhost_discoveries = hash.key?('vhost_discoveries') ? VhostDiscoveryRuleCollection.new(hash['vhost_discoveries']) : nil
      end

      def collect_children
        [
          @templates,
          @metrics,
          @meta,
          @interfaces,
          @metric_discoveries,
          @vhost_discoveries,
        ].compact
      end

      attr_reader :name, :templates, :metrics, :meta, :interfaces, :metric_discoveries, :vhost_discoveries
    end
  end
end
