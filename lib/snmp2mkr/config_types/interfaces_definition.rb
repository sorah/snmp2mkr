require 'snmp2mkr/config_types/base'
require 'snmp2mkr/config_types/oid'
require 'snmp2mkr/config_types/value_definition'

module Snmp2mkr
  module ConfigTypes
    class InterfacesDefinition < Base
      def setup(h)
        raise TypeError, "#{self.class} must be given a Hash" unless h.kind_of?(Hash)
        raise ArgumentError, "#{self.class} hash must have 'keys' (Hash)" unless h['keys'].kind_of?(Hash)
        raise ArgumentError, "#{self.class} hash must have 'match' (Hash)" unless h['match'].kind_of?(Hash)
        raise ArgumentError, "#{self.class} hash must have 'values' (Hash)" unless h['values'].kind_of?(Hash)

        @keys = h['keys'].map do |k, v|
          [k, Oid.new(v)]
        end.to_h
        @match = h['match'].map do |k, v|
          [k, TemplateString.new(v)]
        end.to_h
        @values = h['values'].map do |k, v|
          [k, ValueDefinition.new([k,v])]
        end.to_h
      end

      attr_reader :keys, :match, :values

      def collect_children
        [*@keys.values, *@match.values, *@values.values]
      end
    end
  end
end
