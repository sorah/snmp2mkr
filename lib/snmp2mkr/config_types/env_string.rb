require 'snmp2mkr/config_types/base'

module Snmp2mkr
  module ConfigTypes
    class EnvString < Base
      def setup(str_or_hash)
        @value = case str_or_hash
                 when String
                   str_or_hash
                 when Hash
                   ENV.fetch(str_or_hash.fetch('env'))
                 else
                   raise TypeError, "#{self.class} must be given a String or a Hash with key 'env'"
                 end
      end

      attr_reader :value
    end
  end
end
