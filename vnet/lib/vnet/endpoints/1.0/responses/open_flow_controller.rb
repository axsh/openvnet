# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class OpenFlowController < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::OpenFlowController)
      object.to_hash
    end
  end

  class OpenFlowControllerCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        OpenFlowController.generate(i)
      }
    end
  end
end
