# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class OpenFlowControllerWrapper < Base
    backend_namespace = "open_flow_controllers"

    def to_hash
      {
        :uuid => self.uuid,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
