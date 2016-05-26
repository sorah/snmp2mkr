require 'snmp2mkr/config_types/base'
require 'snmp2mkr/config_types/transformation'

module Snmp2mkr
  module ConfigTypes
    class Transformation < Base
      def setup(h)
        raise TypeError, "#{self.class} must be given an Hash" unless h.kind_of?(Hash)

        @type = h.fetch('type')
        raise TypeError, "#{self.class} type must be a String"  unless @type.kind_of?(String)

        case @type
        when 'persec'
          # do nothing
        else
          raise ArgumentError, "#{self.class} doesn't know type #{type.inspect}"
        end
      end

      attr_reader :type
    end
  end
end


