# -*- coding: utf-8 -*-

module Vnet::Openflow::Filters
  class Base
    include Vnet::Openflow::FlowHelpers
    include Cookies

    # We make a class method out of cookie so we can access
    # it easily in unit tests.
    def self.cookie
      raise NotImplementedError
    end

    def cookie
      self.class.cookie
    end

    def install
      raise NotImplementedError
    end

  end
end
