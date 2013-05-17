# -*- coding: utf-8 -*-

module Vnmgr::Endpoints::V10::Responses
  class Tunnel < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnmgr::ModelWrappers::TunnelWrapper)
      object.to_hash
    end
  end

  class TunnelCollection < Vnmgr::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        Tunnel.generate(i)
      }
    end
  end
end
