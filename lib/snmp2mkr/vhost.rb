require 'snmp2mkr/oid'

module Snmp2mkr
  class Vhost
    def initialize(name:, roles:, metrics:, discovery_name: nil, mib: Mib.default)
      @name = name
      @roles = roles
      @metrics = metrics.map { |v| Metric.new(v.name.evaluate, v.oid.evaluate, transformations: v.transformations, mib: mib) }
      @discovery_name = discovery_name
    end

    attr_reader :name, :roles, :metrics, :discovery_name

    class Metric
      def initialize(name, oid, mib: nil, transformations: [])
        @name = name
        @oid = oid.kind_of?(Oid) ? oid : Oid.new(oid, mib: mib) 
        @transformations = transformations
      end

      attr_reader :name, :oid, :transformations
    end
  end
end
