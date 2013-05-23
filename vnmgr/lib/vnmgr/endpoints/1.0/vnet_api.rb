# -*- coding: utf-8 -*-

require "sinatra"
require "sinatra/vnmgr_api_setup"

module Vnmgr::Endpoints::V10
  class VNetAPI < Sinatra::Base
    class << self
      attr_reader :vnmgr_conf, :dba_conf, :common_conf

      def load_conf(vnmgr_conf, dba_conf, common_conf)
        @vnmgr_conf = Vnmgr::Configurations::Vnmgr.load(vnmgr_conf)
        @dba_conf = Vnmgr::Configurations::Dba.load(dba_conf)
        @common_conf = Vnmgr::Configurations::Common.load(common_conf)
      end

      def storage_backend
        @storage_backend ||= Vnmgr::StorageBackends.backend_class(VNetAPI.vnmgr_conf, VNetAPI.dba_conf, VNetAPI.common_conf)
      end
      alias_method :sb, :storage_backend
    end

    include Vnmgr::Endpoints::V10::Helpers
    register Sinatra::VnmgrAPISetup

    E = Vnmgr::Endpoints::Errors
    R = Vnmgr::Endpoints::V10::Responses

    def parse_params(params,mask)
      final_params = {}
      final_params = params.delete_if {|k,v| !mask.member?(k) }
      final_params.default = nil
      final_params
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
