# -*- coding: utf-8 -*-

require "sinatra"
require "sinatra/vnmgr_api_setup"

module Vnmgr::Endpoints::V10
  class VNetAPI < Sinatra::Base
    include Vnmgr::Endpoints::V10::Helpers
    register Sinatra::VnmgrAPISetup

    M = Vnmgr::ModelWrappers
    E = Vnmgr::Endpoints::Errors
    R = Vnmgr::Endpoints::V10::Responses

    def parse_params(params,mask)
      params.keys.each_with_object({}) do |key, h|
        h[key] = params[key] if mask.member?(key)
      end
    end

    def parse_ipv4(param)
      return nil if param.nil? || param.empty?

      begin
        address = IPAddr.new(param)
        raise(E::ArgumentError, 'Not an IPv4 address.') unless address.ipv4?
        address.to_i
      rescue ArgumentError
        raise(E::ArgumentError, 'Could not parse IPv4 address.')
      end
    end

    def parse_mac(param)
      return nil if param.nil? || param.empty?

      begin
        Trema::Mac.new(param).value
      rescue ArgumentError
        raise(E::ArgumentError, 'Could not parse MAC address.')
      end
    end

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
