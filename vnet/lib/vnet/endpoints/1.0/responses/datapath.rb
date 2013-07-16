# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Datapath < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::Datapath)
      object.to_hash
    end
  end

  class DatapathCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        Datapath.generate(i)
      }
    end
  end
end
