require 'snmp'

module Snmp2mkr
  # Wrapper of SNMP::MIB for future implementation change
  class Mib
    class ModuleNotFound < StandardError; end

    def initialize(load_path: [], modules: [], no_default_load_path: false)
      @load_path = no_default_load_path ? load_path : [*load_path, SNMP::MIB::DEFAULT_MIB_PATH]
      @mib = SNMP::MIB.new

      modules.each do |mod|
        import mod
      end
    end

    attr_reader :load_path

    def import(module_name)
      raise ArgumentError if module_name.include?(?/)

      load_path.each do |path|
        begin
          @mib.load_module(module_name, path)
        rescue Errno::ENOENT
          next
        end

        return
      end

      raise ModuleNotFound, "couldn't find module #{module_name.inspect} from #{load_path.inspect}"
    end

    def oid_to_name(oid)
      @mib.name(oid.to_s)
    end

    def name_to_oid(name)
      @mib.oid(name).to_a
    end
  end
end
