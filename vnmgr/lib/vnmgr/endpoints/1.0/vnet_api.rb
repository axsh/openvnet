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

      def storage_backend
        @storage_backend ||= Vnmgr::StorageBackends.backend_class(VNetAPI.conf)
      end
      alias_method :sb, :storage_backend
    end

    include Vnmgr::Endpoints::V10::Helpers
    register Sinatra::VnmgrAPISetup

    #load_conf(Vnmgr::Constants::VNetAPI::CONF_LOCATION)
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

    def filter_params(params)
      params.delete('splat')
      params.delete('captures')
      params.default = nil
      params
    end

    def storage_backend
      self.class.storage_backend
    end
    alias_method :sb, :storage_backend

    respond_to :json, :yml

    load_namespace('networks')
    load_namespace('vifs')
    load_namespace('dhcp_ranges')
    load_namespace('mac_ranges')
    load_namespace('mac_leases')
    load_namespace('routers')
    load_namespace('tunnels')
    load_namespace('dc_networks')
    load_namespace('datapaths')
    load_namespace('open_flow_controllers')
    load_namespace('ip_addresses')
    load_namespace('ip_leases')
  end
end
