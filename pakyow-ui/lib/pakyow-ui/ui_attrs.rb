module Pakyow
  module UI
    class UIAttrs
      #TODO abstract the common bits from this + ui view to an instructable module
      def initialize
        @instructions = []
      end

      def instruct(method, value)
        @instructions << [method, value]
        self
      end

      def nested_instruct(method, value)
        attrs = UIAttrs.new
        @instructions << [method, value, attrs]
        attrs
      end

      def finalize
        @instructions.map { |instruction|
          if instruction[2].is_a?(UIAttrs)
            instruction[2] = instruction[2].finalize
          end

          instruction
        }
      end

      def method_missing(method, value)
        nested_instruct(method, value)
      end

      def class
        method_missing(:class, nil)
      end

      def id
        method_missing(:id, nil)
      end
    end
  end
end