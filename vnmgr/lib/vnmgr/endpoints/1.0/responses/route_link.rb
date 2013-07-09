# -*- coding: utf-8 -*-

module Vnmgr::Endpoints::V10::Responses
  class RouteLink < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnmgr::ModelWrappers::RouteLink)
      object.to_hash
    end
  end

  class RouteLinkCollection < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        RouteLink.generate(i)
      }
    end
  end
end
