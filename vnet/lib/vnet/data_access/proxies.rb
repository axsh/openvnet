# -*- coding: utf-8 -*-
module Vnet::DataAccess
  class Proxy
    def initialize(conf)
      @conf = conf
    end

    def method_missing(class_name, *args, &block)
      if class_name.present? && args.empty? && Vnet::DataAccess::Models.const_defined?(class_name.to_s.camelize)
        _call_class.new(class_name, @conf).tap do |call|
          define_singleton_method(class_name){ call }
        end
      else
        super
      end
    end

    protected
    def _call_class
      raise "Not implemented"
    end

    class Call
      def initialize(class_name, conf)
        @class_name = class_name
        @conf = conf
      end
    end
  end

  class DbaProxy < Proxy
    protected
    class DbaCall < Call
      def initialize(class_name, conf)
        super
        @actor = DCell::Node[conf.dba_node_id][conf.dba_actor_name]
      end

      def method_missing(method_name, *args, &block)
        @actor.execute(@class_name, method_name, *args, &block)
      end
    end

    def _call_class
      DbaCall
    end
  end

  class DirectProxy < Proxy
    protected
    class DirectCall < Call
      def initialize(class_name, conf)
        super
        @method_caller = Vnet::DataAccess::Models.const_get(class_name.to_s.camelize).new
      end

      def method_missing(method_name, *args, &block)
        @method_caller.send(method_name, *args, &block)
      end
    end

    def _call_class
      DirectCall
    end
  end
end
