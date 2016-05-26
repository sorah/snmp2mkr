require 'thread'

require 'snmp2mkr/config_types/template_collection'
require 'snmp2mkr/snmp'

module Snmp2mkr
  class Host
    def initialize(hostdef, template_collection: Snmp2mkr::ConfigTypes::TemplateCollection.new([]), mib: nil)
      @lock = Mutex.new

      @definition = hostdef
      @templates = resolve_templates(hostdef.templates, template_collection)
      @mib = mib
    end

    def inspect
      "#<#{self.class}: #{name.inspect} (#{templates.map(&:name).inspect})>"
    end

    def name
      definition.name
    end

    attr_reader :definition, :templates, :mib


    def metric_definitions
      @metric_definition ||= templates.map(&:metrics).compact.map(&:evaluate).flat_map(&:values)
    end

    def meta_definitions
      @meta_definitions ||= templates.map(&:meta)
    end

    def interface_definitions
      @interface_definitions ||= templates.map(&:interfaces)
    end

    def metric_discoveries
      @metric_discoveries ||= templates.map(&:metric_discoveries).compact.map(&:evaluate).inject({}) { |r,h| r.merge(h) }
    end

    def vhost_discoveries
      @vhost_discoveries ||= templates.map(&:vhost_discoveries).compact.map(&:evaluate).inject({}) { |r,h| r.merge(h) }
    end

    def snmp(mib: nil, &block)
      Snmp.open(definition.host, port: definition.port, community: definition.snmp.community.evaluate, mib: mib || @mib, &block)
    end

    private


    def resolve_templates(list, collection)
      return [] unless list
      list.evaluate.flat_map do |name|
        template = collection.fetch(name)
        [*resolve_templates(template.templates, collection), template]
      end
    end
  end
end
