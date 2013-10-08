# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class SecurityGroup
    def to_hash
      {
        :uuid => uuid,
        :display_name => display_name,
        :description => description
      }
    end
  end
end
