# -*- coding: utf-8 -*-

module Vnet
  module NodeApi
    class << self
      attr_accessor :raise_on_error
      attr_reader :proxy_class

      def proxy
        if @proxy_class.nil?
          raise "Api proxy class not set."
        end

        @proxy_class.new
      end

      def set_proxy_class(p_class)
        if @proxy_class
          raise "Api proxy class already set."
        end

        @proxy_class = p_class
      end
    end

    class Proxy
      def method_missing(class_name, *args, &block)
        # The const_defined search constructs all the NodeApi::*
        # classes, even if we are using 'rpc', and as such can't do a
        # search to validate the class names.
        if class_name.present? && args.empty?
          _call_class.new(class_name).tap do |call|
            define_singleton_method(class_name){ call }
          end
        else
          super
        end
      end

      protected

      def _call_class
        raise NotImplementedError
      end

      class Call
        def initialize(class_name)
          @class_name = class_name
        end

        def method_missing(method_name, *args, &block)
          _call(method_name, *args, &block)
        rescue => exception
          raise exception if Vnet::NodeApi.raise_on_error
          logger.debug("#{exception.class}: #{exception.to_s}\n\t")
          nil
        end

        private

        def _call(method_name, *args, &block)
          raise NotImplementedError
        end

        def logger
          Celluloid.logger
        end
      end
    end

  end
end

Vnet::NodeApi.raise_on_error = true
