# -*- coding: utf-8 -*-

require "sinatra"
require "sinatra/vnmgr_api_setup"

module Vnmgr::Endpoints::V10
  class VNetAPI < Sinatra::Base
    class << self
      attr_reader :conf

      def load_conf(*files)
        @conf = Vnmgr::Configurations::Vnmgr.load(*files)
      end

      def data_access_proxy
        @data_access_proxy ||= Vnmgr::DataAccess.get_proxy(conf)
      end
      alias_method :data_access, :data_access_proxy
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

    def data_access_proxy
      self.class.data_access_proxy
    end
    alias_method :data_access, :data_access_proxy

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
    load_namespace('network_services')
  end
end
