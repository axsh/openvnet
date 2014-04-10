# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class LeasePolicyBaseInterface < Base
    class << self
      def create(options)
        p ",,,in create(#{options.inspect})"
        super
      end

      def destroy(uuid)
        p ",,,in destroy(#{uuid.inspect})"
        super
      end
    end
  end
end
