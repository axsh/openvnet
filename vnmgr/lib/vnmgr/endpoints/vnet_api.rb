# -*- coding: utf-8 -*-

require "sinatra"
require "sinatra/vnmgr_api_setup"

module Vnmgr::Endpoints
  class VNetAPI < Sinatra::Base
    include Vnmgr::Endpoints::Helpers
    register Sinatra::VnmgrAPISetup

    def parse_params(params,mask)
      final_params = {}

      # Check if the mask is valid
      mask.values.each {|v| raise "Invalid parameters mask" unless v.is_a?(Array) }

      params.each {|k,v|
        if mask[k].member?(v.class)
          final_params[k] = v
        else
          raise "Invalid parameter: '#{v}'. Must be one of [#{v.join(",")}]"
        end
      }

      final_params
    end

    respond_to :json, :yml

    load_namespace('networks')
    load_namespace('vifs')
    load_namespace('mac_ranges')
    load_namespace('dns')
    load_namespace('dhcp')
    load_namespace('dc_networks')
    load_namespace('datapaths')
    load_namespace('openflow_controllers')
  end
end
