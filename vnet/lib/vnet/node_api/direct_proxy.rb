# -*- coding: utf-8 -*-

module Vnet
  module NodeApi
    class DirectProxy < Proxy
      protected
      class DirectCall < Call
        def initialize(class_name)
          super
          @method_caller = Vnet::NodeApi.const_get(class_name.to_s.camelize)
        end

        def _call(method_name, *args, &block)
          @method_caller.send(method_name, *args, &block)
        end
      end

      def _call_class
        DirectCall
      end
    end
  end
end
