module Snmp2mkr
  module ConfigTypes
    class Base
      def initialize(obj, context: {})
        @original = obj
        setup obj
        self.binded_context = context
      end

      def inspect
        "#<#{self.class}: #{@original.inspect} (#{@binded_context.inspect})>"
      end

      def evaluate(context: binded_context, previous: nil)
        value
      end

      def children(type = nil)
        @children ||= collect_children.flat_map { |ch| ch.kind_of?(Base) ? [ch, *ch.children] : [ch] }
        type ? @children.select { |_| type === _ } : @children
      end

      def collect_children
        []
      end

      attr_reader :binded_context

      def bind_context(ctx)
        self.class.new(@original, context: ctx)
      end

      protected

      def binded_context=(o)
        @binded_context = o
        collect_children.each do |child|
          child.binded_context = o
        end
      end
    end
  end
end
