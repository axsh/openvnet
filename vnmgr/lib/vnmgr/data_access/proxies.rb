# -*- coding: utf-8 -*-

module Vnmgr::DataAccess
  class Proxy
    def initialize(conf)
      @conf = conf
    end

    def method_missing(*args)
      class_name = args.first
      if class_name.present? && Vnmgr::Models.const_defined?(class_name.to_s.classify)
        call_class.new(class_name, @conf).tap do |call|
          define_singleton_method(class_name){ call }
        end
      else
        super
      end
    end

    protected
    def call_class
      raise "Not implemented"
    end

    class Call
      def initialize(class_name, conf)
        @class_name = class_name
        @conf = conf
      end

      protected
      def wrap(class_name, data)
        case data
        when Array
          data.map{|d| wrapper_class(class_name).new(d) }
        when Hash
          wrapper_class(class_name).new(data)
        else
          nil
        end
      end

      def wrapper_class(class_name)
        Vnmgr::ModelWrappers.const_get(class_name.to_s.classify)
      end
    end
  end

  class DbaProxy < Proxy
    protected
    class DbaCall < Call
      def initialize(class_name, conf)
        super
        @actor = DCell::Node[conf.dba_node_name][conf.dba_actor_name]
      end

      def method_missing(*args)
        if args.size > 0 && args.first.is_a?(Symbol)
          wrap(@class_name, @actor.execute(@class_name, *args))
        else
          super
        end
      end
    end

    def call_class
      DbaCall
    end
  end

  class DirectProxy < Proxy
    protected
    class DirectCall < Call
      def initialize(class_name, conf)
        super
        @method_caller = Vnmgr::Models.const_get(class_name.to_s.classify)
      end

      def method_missing(*args)
        if args.size > 0 && args.first.is_a?(Symbol)
          wrap(@class_name, @method_caller.send(*args))
        else
          super
        end
      end

      protected
      def wrap(class_name, data)
        hash_data = case data
        when Array
          data.map { |d|
            d.to_hash
          }
        when Vnmgr::Models::Base
          data.to_hash
        when nil
          nil
        else
          raise "Unexpected type: #{data.class}"
        end
        super(class_name, hash_data)
      end
    end

    def call_class
      DirectCall
    end
  end
end
