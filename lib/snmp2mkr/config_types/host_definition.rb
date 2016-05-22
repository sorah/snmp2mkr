require 'snmp2mkr/config_types/base'
require 'snmp2mkr/config_types/templates_list'
require 'snmp2mkr/config_types/host_snmp_definition'

module Snmp2mkr
  module ConfigTypes
    class HostDefinition < Base
      def setup(kv)
        raise TypeError, "#{self.class} must be given an Array (BUG?)" unless kv.kind_of?(Array) && kv.size == 2
        k, h = kv
        @name = k

        raise TypeError, "#{self.class} must be given a Hash" unless h.kind_of?(Hash)
        raise ArgumentError, "#{self.class} hash must have 'host' (String)" unless h['host'].kind_of?(String)
        raise ArgumentError, "#{self.class} hash must have 'snmp' (Hash)" unless h['snmp'].kind_of?(Hash)
        raise ArgumentError, "#{self.class} hash must have 'templates' (Array<String>)" unless h['templates'].kind_of?(Array)

        @host = h['host']
        @port = h.fetch('port', 161)
        @templates = TemplatesList.new(h['templates'])
        @snmp = HostSnmpDefinition.new(h['snmp'])
      end

      attr_reader :host, :port, :templates, :snmp

      def collect_children
        [@templates, @snmp]
      end
    end
  end
end
