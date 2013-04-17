# -*- coding: utf-8 -*-

require "sinatra_base"

module Vnmgr::Endpoints
  class VNetAPI < Sinatra::Base
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
  end
end
