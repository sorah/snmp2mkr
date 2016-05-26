require 'snmp2mkr/oid'

module Snmp2mkr
  class Metric
    def initialize(vhost, name, oid, mib: nil, transformations: [])
      @vhost_name = vhost.name
      @name = name
      @oid = oid.kind_of?(Oid) ? oid : Oid.new(oid, mib: mib) 
      @transformations = transformations
    end

    attr_reader :vhost_name, :name, :oid, :transformations

    def evaluate(varbind, state_holder: nil, time: Time.now)
      if varbind == SNMP::NoSuchObject || varbind == SNMP::NoSuchInstance
        return nil
      end

      if state_holder
        state = state_holder.fetch(self)
      end

      raw = val = varbind.value.to_i

      transformations.each do |xfrm|
        val = transform(xfrm, val, state, time)
      end

      if state_holder
        state_holder.set(self, state.merge(last: val, last_raw: raw, last_at: time))
      end

      return val
    end

    private


    def transform(xfrm, value, state, time)
      case xfrm.type
      when 'persec'
        unless state[:last_raw] && state[:last_at]
          return nil
        end

        delta = value - state[:last_raw]
        return nil if delta < 0
        return delta/(time-state[:last_at])
      end
    end
  end
end
