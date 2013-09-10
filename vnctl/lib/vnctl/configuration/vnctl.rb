# -*- coding: utf-8 -*-

module Vnctl::Configuration
  class Vnctl < Fuguta::Configuration
    param :webapi_uri, :default => '127.0.0.1'
    param :webapi_port, :default => 9090

    def validate(errors)
      #TODO: Make sure the ip and port are valid
    end
  end
end
