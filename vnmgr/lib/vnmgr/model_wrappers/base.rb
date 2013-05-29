# -*- coding: utf-8 -*-
require 'ostruct'

module Vnmgr::ModelWrappers
  class Base < OpenStruct
    class << self
      def set_proxy(conf)
        @@proxy = Vnmgr::DataAccess.get_proxy(conf)
      end

      def _proxy
        @@proxy
      end

      def method_missing(method_name, *args, &block)
        klass = _proxy.send(self.name.demodulize.underscore.to_sym)
        wrap(klass.send(method_name, *args, &block))
      end

      protected
      def wrap(data)
        case data
        when Array
          data.map{|d| self.new(d) }
        when Hash
          self.new(data)
        else
          nil
        end
      end
    end
  end
end
