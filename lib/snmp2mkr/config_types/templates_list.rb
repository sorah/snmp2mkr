require 'snmp2mkr/config_types/base'
require 'snmp2mkr/config_types/template_string'

module Snmp2mkr
  module ConfigTypes
    class TemplatesList < Base
      def setup(ary)
        if !ary.kind_of?(Array) || ary.any? { |_| !_.kind_of?(String) }
          raise TypeError, "#{self.class} must be given an Array<String>"
        end

        @value = ary.map { |_| TemplateString.new(_) }
      end

      def collect_children
        @value
      end

      attr_reader :value

      def evaluate(context: binded_context, previous: nil)
        @value.map { |_| _.evaluate(context: context, previous: previous) }
      end
    end
  end
end
