require 'thread'

require 'snmp2mkr/host'
require 'snmp2mkr/vhost'

module Snmp2mkr
  class HostManager
    def initialize(persist_file: nil)
      @lock = Mutex.new
      @host_id_lock = Mutex.new

      @hosts = {}
      @vhosts = {}
      @persist_file = persist_file
      if @persist_file && File.exist?(@persist_file)
        @persisted = YAML.load_file(@persist_file)
      else
        @persisted = {host_ids: {}}
      end
    end

    attr_reader :persist_file

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

    def each
      return to_enum(__method__) unless block_given?
      @vhosts.each do |name, hs|
        host = host(name)
        yield host, hs
      end
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

    def mackerel_host_id(vh)
      @persisted[:host_ids][vh.name]
    end

    def set_mackerel_host_id(vh, host_id)
      @host_id_lock.synchronize do
        @persisted[:host_ids][vh.name] = host_id
        persist
      end
    end

    def set_mackerel_host_id_safe(vh)
      @host_id_lock.synchronize do
        host_id = mackerel_host_id(vh)
        return host_id if host_id
        host_id = yield(vh)
        raise TypeError unless host_id
        @persisted[:host_ids][vh.name] = host_id.to_s
        persist
        return host_id
      end
    end

    def persist
      @lock.synchronize do
        File.write persist_file, "#{@persisted.to_yaml}\n"
      end
    end
  end
end
