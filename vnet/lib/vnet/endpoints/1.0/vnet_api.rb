# -*- coding: utf-8 -*-

require "sinatra"
require "sinatra/vnet_api_setup"

module Vnet::Endpoints::V10
  class VnetAPI < Sinatra::Base
    include Vnet::Endpoints::V10::Helpers
    register Sinatra::VnetAPISetup

    M = Vnet::ModelWrappers
    E = Vnet::Endpoints::Errors
    R = Vnet::Endpoints::V10::Responses

    def pop_uuid(model, params, key = "uuid")
      uuid = params.delete(key)
      model[uuid] || raise(E::UnknownUUIDResource, uuid)
    end

    def check_uuid_syntax(model, uuid)
      model.valid_uuid_syntax?(uuid) || raise(E::InvalidUUID, uuid)
    end

    def check_and_trim_uuid(model, params)
      if params.has_key?("uuid")
        check_uuid_syntax(model, params["uuid"])
        raise E::DuplicateUUID, params["uuid"] unless model[params["uuid"]].nil?

        params["uuid"] = model.trim_uuid(params["uuid"])
      end
    end

    def check_syntax_and_pop_uuid(model, params, key = "uuid")
      check_uuid_syntax(model, params[key])
      pop_uuid(model, params, key)
    end

    def parse_params(params, mask)
      params.keys.each_with_object(ActiveSupport::HashWithIndifferentAccess.new) do |key, h|
        h[key] = params[key] if mask.member?(key)
      end
    end

    def required_params(params, mask)
      mask.each do |key|
        raise E::MissingArgument, key if params[key].nil? || params[key].empty?
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

    load_namespace('datapaths')
    load_namespace('dc_networks')
    load_namespace('dhcp_ranges')
    load_namespace('ip_addresses')
    load_namespace('ip_leases')
    load_namespace('mac_leases')
    load_namespace('mac_ranges')
    load_namespace('networks')
    load_namespace('network_services')
    load_namespace('open_flow_controllers')
    load_namespace('routes')
    load_namespace('route_links')
    load_namespace('vifs')
  end
end
