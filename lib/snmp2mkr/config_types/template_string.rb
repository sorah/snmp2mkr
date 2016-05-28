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
        @value.gsub(/\#{(?:(.+) )?(.+?)}/) do |_|
          val = context[$2 || $2.to_sym] or raise MissingContextVariable.new("variable #{$1.inspect} is missing from context")
          if $1
            $1.split(' ').reverse_each.inject(val) do |r, filter_name|
              filter r, filter_name
            end
          else
            val
          end
        end
      end

      def filter(value, filter_name)
        case filter_name
        when 'escape_dot'
          value.gsub('.','-')
        else 
          raise ArgumentError "Unknown filter #{filter_name.inspect}"
        end
      end
    end
  end
end
