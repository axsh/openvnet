# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class DcNetwork < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::DcNetwork)
      object.to_hash
    end
  end

  class DcNetworkCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        DcNetwork.generate(i)
      }
    end
  end
end
