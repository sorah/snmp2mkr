require 'snmp2mkr/mib'
require 'snmp2mkr/metric'

module Snmp2mkr
  class Vhost
    def initialize(name:, roles:, metrics:, discovery_name: nil, mib: Mib.default)
      @name = name
      @roles = roles
      @metrics = metrics.map { |v| Metric.new(self, v.name.evaluate, v.oid.evaluate, transformations: v.transformations, mib: mib) }
      @discovery_name = discovery_name
    end

    attr_reader :name, :roles, :metrics, :discovery_name
  end
end
