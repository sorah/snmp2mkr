module Snmp2mkr
  def self.Oid(obj)
    if obj.is_a?(Oid)
      obj
    else
      Oid.new(obj)
    end
  end

  class Oid
    def initialize(obj, mib: nil, name: nil)
      case obj
      when Array
        @ary = obj.map(&:to_i)
      when String
        if obj.include?('::')
          @name = obj
          @ary = mib.name_to_oid(obj)
        else
          @ary = obj.split('.').map(&:to_i)
        end
      end
      @str = @ary.map(&:to_s).join('.')

      case
      when name
        @name = name
      when mib
        @name ||= mib.oid_to_name(self)
      end
    end

    attr_reader :name

    def to_a
      @ary
    end

    def to_s
      @str
    end

    def ==(o)
      self.class == o.class && self.to_s == o.to_s
    end

    def subtree?(o)
      other = Snmp2mkr::Oid(o)
      self.to_a.size < other.to_a.size &&
        other.to_a[0,self.to_a.size] == self.to_a
    end

    def subtree_of?(o)
      other = Snmp2mkr::Oid(o)
      other.subtree?(self)
    end

    def index_of(o)
      other = Snmp2mkr::Oid(o)
      raise ArgumntError, "#{o.inspect} is not subtree of #{self.inspect} " unless other.subtree?(self)
      self.to_a[other.to_a.size..-1].map(&:to_s).join('.')
    end

    def inspect
      "#<#{self.class}: #{to_s}#{@name && " (#{@name})"}>"
    end
  end
end
