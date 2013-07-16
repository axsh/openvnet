# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class RouteLink < Base

    def to_hash
      {
        :uuid => self.uuid,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
