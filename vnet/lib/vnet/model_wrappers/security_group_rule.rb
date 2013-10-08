# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class SecurityGroupRule
    def to_hash
      {
        :permission => permission
      }
    end
  end
end
