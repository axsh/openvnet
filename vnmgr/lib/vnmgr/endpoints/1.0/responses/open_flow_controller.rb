# -*- coding: utf-8 -*-

module Vnmgr::Endpoints::V10::Responses
  class OpenFlowController < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnmgr::ModelWrappers::OpenFlowControllerWrapper)
      object.to_hash
    end
  end

  class OpenFlowControllerCollection < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        OpenFlowController.generate(i)
      }
    end
  end
end
