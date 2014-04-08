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

    DEFAULT_PAGINATION_LIMIT = 30

    def config
      Vnet::Configurations::Webapi.conf
    end

    def pop_uuid(model, params, key = "uuid", fill = {})
      uuid = params.delete(key)
      model.batch[uuid].commit(:fill => fill) || raise(E::UnknownUUIDResource, "#{model.name.split("::").last}##{key}: #{uuid}")
    end

    def check_uuid_syntax(model, uuid)
      model.valid_uuid_syntax?(uuid) || raise(E::InvalidUUID, "#{model.name.split("::").last}#uuid: #{uuid}")
    end

    def check_and_trim_uuid(model, params)
      check_uuid_syntax(model, params["uuid"])
      raise E::DuplicateUUID, params["uuid"] unless model[params["uuid"]].nil?

      params["uuid"] = model.trim_uuid(params["uuid"])
    end

    def check_syntax_and_pop_uuid(model, params, key = "uuid", fill = {})
      check_uuid_syntax(model, params[key])
      pop_uuid(model, params, key, fill)
    end

    def check_syntax_and_get_id(model, params, uuid_key = "uuid", id_key = "id", fill = {})
      check_uuid_syntax(model, params[uuid_key])
      model = pop_uuid(model, params, uuid_key, fill)
      params[id_key] = model.id

      model
    end

    def parse_params(params, mask)
      mask.each_with_object(ActiveSupport::HashWithIndifferentAccess.new) do |key, h|
        h[key] = params[key] if params.key?(key)
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
      uuid = @params[:uuid]
      # TODO don't need to find model here
      check_syntax_and_pop_uuid(model_wrapper, @params)
      model_wrapper.destroy(uuid)
      respond_with([uuid])
    end

    # TODO remove fill
    def get_all(class_name, fill = {})
      model_wrapper = M.const_get(class_name)
      response = R.const_get("#{class_name}Collection")
      limit = @params[:limit] || config.pagination_limit
      offset = @params[:offset] || 0
      total_count = model_wrapper.batch.count.commit
      items = model_wrapper.batch.dataset.offset(offset).limit(limit).all.commit(fill: fill)
      pagination = {
        "total_count" => total_count,
        "offset" => offset,
        "limit" => limit,
      }
      respond_with(response.generate_with_pagination(pagination, items))
    end

    def get_by_uuid(class_name, fill = {})
      model_wrapper = M.const_get(class_name)
      response = R.const_get(class_name)
      object = check_syntax_and_pop_uuid(model_wrapper, @params, "uuid", fill)
      respond_with(response.generate(object))
    end

    def update_by_uuid(class_name, accepted_params, fill = {})
      model_wrapper = M.const_get(class_name)
      response = R.const_get(class_name)

      params = parse_params(@params, accepted_params + ["uuid"])
      # TODO don't need to find model here
      check_syntax_and_pop_uuid(model_wrapper, params)
      # This yield is for extra argument validation
      yield(params) if block_given?

      updated_object = model_wrapper.batch.update(@params["uuid"], params).commit(:fill => fill)
      respond_with(response.generate(updated_object))
    end

    def post_new(class_name, accepted_params, required_params, fill = {})
      model_wrapper = M.const_get(class_name)
      response = R.const_get(class_name)

      params = parse_params(@params, accepted_params)
      check_required_params(params, required_params)
      check_and_trim_uuid(model_wrapper, params) if params["uuid"]

      # This yield is for extra argument validation
      yield(params) if block_given?
      object = model_wrapper.batch.create(params).commit(:fill => fill)
      respond_with(response.generate(object))
    end

    def show_relations(class_name, response_method)
      limit = @params[:limit] || config.pagination_limit
      offset = @params[:offset] || 0
      object = check_syntax_and_pop_uuid(M.const_get(class_name), @params)
      total_count = object.batch.send(response_method).count.commit
      items = object.batch.send("#{response_method}_dataset").offset(offset).limit(limit).all.commit
      pagination = {
        "total_count" => total_count,
        "offset" => offset,
        "limit" => limit,
      }

      response = R.const_get("#{response_method.to_s.classify}Collection")
      respond_with(response.generate_with_pagination(pagination, items))
    end

    respond_to :json, :yml

    load_namespace('datapaths')
    load_namespace('dns_services')
    load_namespace('interfaces')
    load_namespace('ip_leases')
    load_namespace('ip_ranges')
    load_namespace('lease_policies')
    load_namespace('mac_leases')
    load_namespace('networks')
    load_namespace('network_services')
    load_namespace('routes')
    load_namespace('route_links')
    load_namespace('security_groups')
    load_namespace('translations')
    load_namespace('vlan_translations')
  end
end
