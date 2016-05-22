require 'snmp2mkr/config_types/base'
require 'snmp2mkr/config_types/oid'
require 'snmp2mkr/config_types/template_string'
require 'snmp2mkr/config_types/transformation'

module Snmp2mkr
  module ConfigTypes
    class MetricDefinition < Base
      def setup(kv)
        raise TypeError, "#{self.class} must be given an Array (BUG?)" unless kv.kind_of?(Array) && kv.size == 2
        k, v = kv

        raise ArgumentError, "#{self.class} key must be String" unless k.kind_of?(String)
        raise ArgumentError, "#{self.class} value must be String or Hash" unless v.kind_of?(String) || v.kind_of?(Hash)

        if v.kind_of?(String)
          v = {'oid' => v}
        end

        @name = TemplateString.new(k)
        @oid = Oid.new(TemplateString.new(v.fetch('oid')))
        ts = v['transformations'] || v['transform'] || []
        raise TypeError, "#{self.class} transformations must be an Array" unless ts.kind_of?(Array)
        @transformations = ts.map { |_| Transformation.new(_) }
      end

      attr_reader :name, :oid, :transformations

      def collect_children
        [@name, @oid, *@transformations]
      end
    end
  end
end
