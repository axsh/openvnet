# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class SecurityGroup < Base
    def to_hash
      {
        :uuid => uuid,
        :display_name => display_name,
        :rules => rules,
        :description => description
      }
    end
  end
end
