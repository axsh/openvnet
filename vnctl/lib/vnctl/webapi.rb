# -*- coding: utf-8 -*-

module Vnctl
  class WebApi
    include HTTParty
    base_uri "#{Vnctl.conf.webapi_uri}:#{Vnctl.conf.webapi_port}"
  end
end
