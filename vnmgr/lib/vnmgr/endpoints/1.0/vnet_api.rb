# -*- coding: utf-8 -*-

require "sinatra"
require "sinatra/vnmgr_api_setup"

module Vnmgr::Endpoints::V10
  class VNetAPI < Sinatra::Base
    class << self
      attr_reader :conf

      def load_conf(conf_path)
        @conf = Vnmgr::Configurations::Vnmgr.load(conf_path)
      end
    end

    include Vnmgr::Endpoints::V10::Helpers
    register Sinatra::VnmgrAPISetup

    load_conf(Vnmgr::Constants::VNetAPI::CONF_LOCATION)
    SB = Vnmgr::StorageBackends.backend_class(VNetAPI.conf)
    E = Vnmgr::Endpoints::Errors
    R = Vnmgr::Endpoints::V10::Responses

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
