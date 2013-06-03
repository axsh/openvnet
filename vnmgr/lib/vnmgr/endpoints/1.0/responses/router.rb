# -*- coding: utf-8 -*-

module Vnmgr::Endpoints::V10::Responses
  class Router < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnmgr::ModelWrappers::Router)
      object.to_hash
    end
  end

  class RouterCollection < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        Router.generate(i)
      }
    end
  end
end
