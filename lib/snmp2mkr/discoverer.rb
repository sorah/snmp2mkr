require 'logger'
require 'snmp2mkr/config_types/oid'
require 'snmp2mkr/mib'
require 'snmp2mkr/oid'
require 'snmp2mkr/vhost'

module Snmp2mkr
  class Discoverer
    def initialize(host, host_manager: nil, logger: Logger.new(File::NULL), mib: Mib.default)
      @host = host
      @host_manager = host_manager
      @logger = logger
      @mib = mib
    end

    def inspect
      "#<#{self.class}:#{'%x' % __id__}, #{host.name.inspect}>"
    end

    attr_reader :host, :host_manager, :logger, :mib

    def perform!
      if host_manager
        host_manager.set_vhosts(host.name, vhosts)
      end

      vhosts
    end

    def vhosts
      @vhosts ||= [
        primary_vhost,
        *discover_vhosts(host.vhost_discoveries),
      ]
    end

    def primary_vhost
      @primary_vhost ||= Vhost.new(
        name: host.name,
        roles: host.definition.roles,
        metrics: host.metric_definitions + discover_metrics(host.metric_discoveries),
        mib: mib
      )
    end

    def snmp_trees
      @snmp_trees ||= host.snmp do |snmp|
        oids = [*host.metric_discoveries.values, *host.vhost_discoveries.values].
          compact.
          flat_map { |_| _.keys.values.map(&:evaluate) }.
          uniq.
          map { |_| Snmp2mkr::Oid.new(mib.name_to_oid(_), name: _) }.
          uniq.
          sort_by { |_| -_.to_a.size }

        oids.map do |oid|
          [oid.to_s, snmp.subtree(oid).to_a]
        end.to_h
      end
    end

    private

    def discover_metrics(rules)
      rules.each_value.flat_map do |rule|
        rule_keys = rule.keys.map { |k, confoid| [k, Snmp2mkr::Oid.new(confoid.evaluate, mib: mib)] }
        primary_oid = rule_keys.first.last.to_s

        snmp_trees[primary_oid].flat_map do |index_vb|
          index = index_vb.oid.index_of(primary_oid)
          keys = rule_keys.map do |k, oid|
            [k, snmp_trees[oid.to_s].find{ |vb| vb.oid.index_of(oid) == index }.value.to_s]
          end.to_h
          keys['index'] = index

          rule.metrics.bind_context(keys).evaluate.values
        end
      end
    end

    def discover_vhosts(rules)
      rules.each.flat_map do |rule_name, rule|
        rule_keys = rule.keys.map { |k, confoid| [k, Snmp2mkr::Oid.new(confoid.evaluate, mib: mib)] }
        primary_oid = rule_keys.first.last.to_s

        snmp_trees[primary_oid].flat_map do |index_vb|
          index = index_vb.oid.index_of(primary_oid)
          keys = rule_keys.map do |k, oid|
            [k, snmp_trees[oid.to_s].find{ |vb| vb.oid.index_of(oid) == index }.value.to_s]
          end.to_h
          keys['index'] = index

          bind_rule = rule.bind_context(keys)
          Vhost.new(
            name: bind_rule.name.evaluate,
            roles: bind_rule.roles.map(&:evaluate),
            metrics: bind_rule.metrics.evaluate.values,
            discovery_name: rule_name,
            mib: mib,
          )
        end
      end
    end
  end
end
