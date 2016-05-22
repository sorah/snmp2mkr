require 'snmp2mkr/config_types/base'

module Snmp2mkr
  module ConfigTypes
    class HostSnmpDefinition < Base
      def setup(h)
        @version = h.fetch('version', '2c')
        @community = EnvString.new(h.fetch('community', 'public'))
      end

      attr_reader :version, :community

      def collect_children
        [@community]
      end
    end
  end
end
