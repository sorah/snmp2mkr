module Snmp2mkr
  module ConfigTypes
    class Base
      def initialize(obj, context: {})
        @original = obj
        @binded_context = context
        setup obj
      end

      def evaluate(context: binded_context, previous: nil)
        value
      end

      def children(type: nil)
        @children ||= collect_children.flat_map { |ch| ch.kind_of?(Base) ? [ch, *ch.children] : [ch] }
        @children.select { |_| type === _ }
      end

      def collect_children
        []
      end

      attr_reader :binded_context

      def bind_context(ctx)
        self.class.new(@original, context: ctx)
      end
    end
  end
end
