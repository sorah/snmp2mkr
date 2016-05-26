require 'snmp'

require 'snmp2mkr/mib'
require 'snmp2mkr/oid'

module Snmp2mkr
  # Wrapper of SNMP::Manager for future implementation change
  class Snmp
    class Closed < StandardError; end

    def self.default_mib; @default_mib ||= Mib.new; end
    def self.default_mib=(o); @default_mib = o; end

    def self.open(*args)
      conn = new(*args)
      return conn unless block_given?

      begin
        yield conn
      ensure
        conn.close
      end
    end

    def initialize(host, port: 161, community: 'public', mib: nil, &block) # :nodoc:
      @manager = SNMP::Manager.new(host: host, port: port, community: community, &block)
      @mib = mib || self.class.default_mib
    end

    attr_reader :mib

    def close
      @manager.close
      @manager = nil
    end

    def closed?
      @manager.nil?
    end

    def get(*oids_)
      raise Closed if closed?
      return to_enum(__method__, *oids_) unless block_given?

      oids = oids_.flatten
      @manager.get(oids.map(&:to_s)).varbind_list.each do |varbind|
        yield Varbind.new(Snmp2mkr::Oid.new(varbind.name.to_a, mib: mib), varbind.value)
      end
    end

    def subtree(oid_)
      raise Closed if closed?
      return to_enum(__method__, oid_) unless block_given?

      oid = oid_.kind_of?(Snmp2mkr::Oid) ? oid_ : Snmp2mkr::Oid.new(mib.name_to_oid(oid_), name: oid_.to_s)
      pointer = oid

      while pointer
        @manager.get_bulk(0, 20, pointer.to_s).varbind_list.each do |varbind|
          if varbind == SNMP::EndOfMibView
            pointer = nil
            break
          end

          vb = Varbind.new(Snmp2mkr::Oid.new(varbind.name.to_a, mib: mib), varbind.value)
          unless oid.subtree?(vb.oid)
            pointer = nil
            break
          end

          yield vb

          pointer = vb.oid
        end
      end

      nil
    end

    class Varbind
      def initialize(oid , value)
        @oid = oid
        @value = value
      end
      attr_reader :oid, :value
    end
  end
end
