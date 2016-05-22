require 'snmp2mkr/config_types/base'

module Snmp2mkr
  module ConfigTypes
    class RawString < Base
      def setup(str)
        raise TypeError, "#{self.class} must be given a String" unless str.kind_of?(String)
        @value = str
      end

      attr_reader :value
    end
  end
end
