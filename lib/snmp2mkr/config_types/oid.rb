require 'snmp2mkr/config_types/base'
require 'snmp2mkr/config_types/template_string'
require 'snmp2mkr/config_types/raw_string'

module Snmp2mkr
  module ConfigTypes
    class Oid < Base
      def setup(str)
        raise TypeError, 'Oid must be given a String or a TemplateString' unless str.kind_of?(String) || str.kind_of?(TemplateString)
        @value = str.is_a?(String) ? RawString.new(str) : str
      end

      attr_reader :value

      def collect_children
        [@value]
      end

      def evaluate(context: binded_context, previous: nil)
        value.evaluate(context: context, previous: previous)
      end
    end
  end
end
