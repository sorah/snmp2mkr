require 'snmp2mkr/vhost'

module Snmp2mkr
  module SendRequests
    class Graphs
      def initialize(graphdefs)
        @graphdefs = graphdefs
      end

      def inspect
        "#<#{self.class}:#{'%x' % __id__}: #{graphdefs.map{ |_| _[:name] }.inspect}>"
      end

      attr_reader :graphdefs
    end
  end
end
