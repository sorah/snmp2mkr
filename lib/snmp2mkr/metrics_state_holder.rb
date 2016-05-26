require 'thread'

module Snmp2mkr
  class MetricsStateHolder
    def initialize
      @lock = Mutex.new
      @hash = {}
    end

    def set(metric, data)
      @lock.synchronize do
        @hash[[metric.vhost_name, metric.name]] = data
      end
    end

    def fetch(metric)
      @hash[[metric.vhost_name, metric.name]] || {}
    end
  end
end
