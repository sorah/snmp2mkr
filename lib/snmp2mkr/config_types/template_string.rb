require 'snmp2mkr/config_types/base'

module Snmp2mkr
  module ConfigTypes
    class TemplateString < Base
      class MissingContextVariable < StandardError; end

      def setup(str)
        raise TypeError, 'TemplateString must be given a String' unless str.kind_of?(String)
        @value = str
      end

      attr_reader :value

      def evaluate(context: binded_context, previous: nil)
        @value.gsub(/\#{(.+?)}/) do |_|
          context[$1 || $1.to_sym] or raise MissingContextVariable.new("variable #{$1.inspect} is missing from context")
        end
      end
    end
  end
end
