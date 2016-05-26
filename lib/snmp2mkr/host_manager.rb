require 'thread'

require 'snmp2mkr/host'
require 'snmp2mkr/vhost'

module Snmp2mkr
  class HostManager
    def initialize
      @lock= Mutex.new

      @hosts = {}
      @vhosts = {}
    end

    def add_host(host)
      @lock.synchronize do
        @hosts[host.name] = host
      end
    end

    def host(host)
      @hosts[host.kind_of?(Host) ? host.name : host.to_s]
    end

    def set_vhosts(name, vhosts)
      @lock.synchronize do
        @vhosts[host(name).name] = vhosts
      end
    end

    def vhosts(name)
      @vhosts[host(name).name]
    end

    def each_host(&block)
      @hosts.each_value(&block)
    end

    def each_vhost
      return to_enum(__method__) unless block_given?
      @vhosts.each_value do |hs|
        hs.each do |vhost|
          yield vhost
        end
      end
    end
  end
end
