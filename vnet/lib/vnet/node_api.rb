# -*- coding: utf-8 -*-

module Vnet
  module NodeApi
    class << self
      attr_accessor :raise_on_error
      attr_reader :proxy

      def set_api_proxy(new_proxy)
        if @proxy
          raise "Api proxy is already set."
        end

        @proxy = new_proxy
      end
    end
  end
end

require_relative("node_api/proxies")

Vnet::NodeApi.raise_on_error = true
