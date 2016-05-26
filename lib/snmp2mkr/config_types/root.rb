require 'snmp2mkr/config_types/base'

require 'snmp2mkr/config_types/host_collection'
require 'snmp2mkr/config_types/template_collection'
require 'snmp2mkr/config_types/env_string'

module Snmp2mkr
  module ConfigTypes
    class Root < Base
      def setup(hash)
        raise TypeError, "#{self.class} must be given a Hash" unless hash.kind_of?(Hash)

        @mib_load_path = hash.fetch('mib_load_path', [])
        raise TypeError, "mib_load_path should be an Array" unless @mib_load_path.kind_of?(Array)

        @hosts = HostCollection.new(hash.fetch('hosts'))
        @templates = TemplateCollection.new(hash.fetch('templates'))
        @persist_file = EnvString.new(hash.fetch('persist_file'))
        @api_key = EnvString.new(hash.fetch('api_key'))
      end

      def collect_children
        [
          @hosts,
          @templates,
          @persist_file,
          @api_key,
        ].compact
      end

      attr_reader :hosts, :templates, :persist_file, :api_key, :mib_load_path
    end
  end
end
