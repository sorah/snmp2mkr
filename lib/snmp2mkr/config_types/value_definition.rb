require 'snmp2mkr/config_types/base'
require 'snmp2mkr/config_types/oid'
require 'snmp2mkr/config_types/template_string'
require 'snmp2mkr/config_types/raw_string'
require 'snmp2mkr/config_types/transformation'

module Snmp2mkr
  module ConfigTypes
    class ValueDefinition < Base
      def setup(kv)
        raise TypeError, "#{self.class} must be given an Array (BUG?)" unless kv.kind_of?(Array) && kv.size == 2
        k, v = kv
        @name = k

        raise ArgumentError, "#{self.class} key must be String" unless k.kind_of?(String)
        raise ArgumentError, "#{self.class} value must be String or Hash" unless v.kind_of?(String) || v.kind_of?(Hash)

        if v.kind_of?(String)
          v = {'value' => TemplateString.new(v), 'type' => 'string'}
        end

        @type = v.fetch('type')
        raise TypeError, "#{self.class} value, key 'type' must be a String" unless @type.kind_of?(String)

        @value = v['value']
        @value = RawString.new(v['value']) if @value.kind_of?(String)
      end

      attr_reader :name, :type, :value

      def collect_children
        [@value]
      end
    end
  end
end
