# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class SecurityGroupRule < Base
    def to_hash
      {
        :permission => permission
      }
    end
  end
end
