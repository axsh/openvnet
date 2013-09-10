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
      check_uuid_syntax(model, params["uuid"])
      raise E::DuplicateUUID, params["uuid"] unless model[params["uuid"]].nil?

      params["uuid"] = model.trim_uuid(params["uuid"])
    end

    def check_syntax_and_pop_uuid(model, params, key = "uuid")
      check_uuid_syntax(model, params[key])
      pop_uuid(model, params, key)
    end

    def check_syntax_and_get_id(model, params, uuid_key = "uuid", id_key = "id")
      check_uuid_syntax(model, params[uuid_key])
      model = pop_uuid(model, params, uuid_key)
      params[id_key] = model.id
    end

    def parse_params(params, mask)
      params.keys.each_with_object(ActiveSupport::HashWithIndifferentAccess.new) do |key, h|
        h[key] = params[key] if mask.member?(key)
      end
    end

    def check_required_params(params, mask)
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

    def delete_by_uuid(class_name)
      model_wrapper = M.const_get(class_name)
      mw = check_syntax_and_pop_uuid(model_wrapper, @params)
      mw.batch.destroy.commit
      respond_with([mw.uuid])
    end

    def get_all(class_name)
      model_wrapper = M.const_get(class_name)
      response = R.const_get("#{class_name}Collection")
      respond_with(
        response.generate(model_wrapper.all)
      )
    end

    def get_by_uuid(class_name)
      model_wrapper = M.const_get(class_name)
      response = R.const_get(class_name)
      object = check_syntax_and_pop_uuid(model_wrapper, @params)
      respond_with(response.generate(object))
    end

    def update_by_uuid(class_name, accepted_params)
      model_wrapper = M.const_get(class_name)
      response = R.const_get(class_name)

      params = parse_params(@params, accepted_params + ["uuid"])
      object = check_syntax_and_pop_uuid(model_wrapper, params)
      # This yield is for extra argument validation
      yield(params) if block_given?
      object.batch.update(params).commit

      updated_object = model_wrapper[@params["uuid"]]
      respond_with(response.generate(updated_object))
    end

    def post_new(class_name, accepted_params, required_params)
      model_wrapper = M.const_get(class_name)
      response = R.const_get(class_name)

      params = parse_params(@params, accepted_params)
      check_required_params(params, required_params)
      check_and_trim_uuid(model_wrapper, params) if params["uuid"]

      # This yield is for extra argument validation
      yield(params) if block_given?
      object = model_wrapper.create(params)
      respond_with(response.generate(object))
    end

    def show_relations(class_name, response_method)
      object = check_syntax_and_pop_uuid(M.const_get(class_name), @params)
      respond_with(R.const_get(class_name).send(response_method, object))
    end

    respond_to :json, :yml

    load_namespace('datapaths')
    load_namespace('dhcp_ranges')
    load_namespace('ip_addresses')
    load_namespace('ip_leases')
    load_namespace('mac_leases')
    load_namespace('networks')
    load_namespace('network_services')
    load_namespace('routes')
    load_namespace('route_links')
    load_namespace('vifs')
  end
end
