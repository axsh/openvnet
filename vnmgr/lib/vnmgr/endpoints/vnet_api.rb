# -*- coding: utf-8 -*-

require "sinatra_base"

module Vnmgr::Endpoints
  class VNetAPI < Sinatra::Base
    def parse_params(params,mask)
      final_params = {}

      # Check if the mask is valid
      # mask.values.each {|v| raise "A " }

      params.each {|k,v|
        final_params[k] = v if mask[k].member?(v.class)
      }

      final_params
    end

    respond_to :json, :yml

    load_namespace('networks')
  end
end