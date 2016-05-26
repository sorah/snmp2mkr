module Snmp2mkr
  module SendRequests
    class HostInformation
      def initialize(vhost, meta:, interfaces:)
        @vhost = vhost
        @meta = meta

        @interfaces = interfaces
      end

      attr_reader :vhost, :meta, :interfaces
    end
  end
end
