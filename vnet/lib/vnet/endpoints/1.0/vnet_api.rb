# -*- coding: utf-8 -*-

require "sinatra"
require "sinatra/vnet_api_setup"
require "sinatra/browse"

module Vnet::Endpoints::V10
  class VnetAPI < Sinatra::Base
    include Vnet::Endpoints::V10::Helpers
    include Vnet::Endpoints::V10::Helpers::UUID
    include Vnet::Endpoints::V10::Helpers::Parsers

    register Sinatra::VnetAPISetup
    register Sinatra::Browse

    M = Vnet::ModelWrappers
    E = Vnet::Endpoints::Errors
    R = Vnet::Endpoints::V10::Responses
    C = Vnet::Constants
    H = Vnet::Helpers

    DEFAULT_PAGINATION_LIMIT = 30

    def config
      Vnet::Configurations::Webapi.conf
    end

    # Remove the splat and captures parameters so we can pass @params directly
    # to the model classes
    def remove_system_parameters
      @params.delete("splat")
      @params.delete("captures")
    end

    def vnet_default_on_error(error_hash)
      if error_hash[:reason] == :required
        raise E::MissingArgument, error_hash[:parameter]
      else
        raise E::ArgumentError, {
          error: "parameter validation failed",
          parameter: error_hash[:parameter],
          value: error_hash[:value],
          reason: error_hash[:reason]
        }
      end
    end

    default_on_error { |error_hash| vnet_default_on_error(error_hash) }

    def self.param_uuid(model, name = :uuid, options = {})
      #TODO: Allow access to default_on_error in here
      error_handler = proc { |result|
        case result[:reason]
        when :format
          raise(E::InvalidUUID, "#{model.name.split("::").last}#uuid: #{result[:value]}")
        else
          vnet_default_on_error(result)
        end
      }

      final_options = {
        format: Vnet::Endpoints::V10::Helpers::UUID.regex(model.uuid_prefix),
        on_error: error_handler
      }

      final_options.merge!(options)

      param name, :String, final_options
    end

    def delete_by_uuid(class_name)
      model_wrapper = M.const_get(class_name)
      uuid = @params[:uuid]
      # TODO don't need to find model here
      check_syntax_and_pop_uuid(model_wrapper)
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
      object = check_syntax_and_pop_uuid(model_wrapper, "uuid", fill)
      respond_with(response.generate(object))
    end

    def update_by_uuid(class_name, fill = {})
      model_wrapper = M.const_get(class_name)
      response = R.const_get(class_name)

      model = check_syntax_and_pop_uuid(model_wrapper)

      # This yield is for extra argument validation
      yield(params) if block_given?

      remove_system_parameters

      updated_object = model_wrapper.batch.update(model.uuid, params).commit(:fill => fill)
      respond_with(response.generate(updated_object))
    end

    def post_new(class_name, fill = {})
      model_wrapper = M.const_get(class_name)
      response = R.const_get(class_name)

      check_and_trim_uuid(model_wrapper) if params["uuid"]

      # This yield is for extra argument validation
      yield(params) if block_given?
      object = model_wrapper.batch.create(params).commit(:fill => fill)
      respond_with(response.generate(object))
    end

    def show_relations(class_name, response_method)
      limit = @params[:limit] || config.pagination_limit
      offset = @params[:offset] || 0
      object = check_syntax_and_pop_uuid(M.const_get(class_name))
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

    def check_ipv4_address_subnet(network)
      ipv4_address = params["ipv4_address"]
      if ipv4_address
        valid, parsed_ipv4_nw, parsed_ipv4 = H::IpAddress.valid_in_subnet(network, ipv4_address)

        if !valid
          raise(E::ArgumentError, "IP Address %s not in subnet %s." %
            [parsed_ipv4, parsed_ipv4_nw])
        end
      end
    end

    respond_to :json, :yml

    load_namespace('datapaths')
    load_namespace('dns_services')
    load_namespace('filters')
    load_namespace('interfaces')
    load_namespace('ip_leases')
    load_namespace('ip_range_groups')
    load_namespace('ip_lease_containers')
    load_namespace('ip_retention_containers')
    load_namespace('lease_policies')
    load_namespace('mac_leases')
    load_namespace('mac_range_groups')
    load_namespace('networks')
    load_namespace('network_services')
    load_namespace('routes')
    load_namespace('route_links')
    load_namespace('security_groups')
    load_namespace('translations')
    load_namespace('topologies')
    load_namespace('vlan_translations')
  end
end
