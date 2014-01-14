# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/network_services' do
  put_post_shared_params = [
    "interface_uuid",
    "incoming_port",
    "outgoing_port"
  ]

  fill_options = [ :interface ]

  post do
    accepted_params = put_post_shared_params + [:uuid, :type]
    required_params = [:type]

    # TODO remove me
    # this is only for compatibility
    params[:type] = params[:display_name] if params[:display_name] && !params[:type]

    post_new(:NetworkService, accepted_params, required_params, fill_options) { |params|
      check_syntax_and_get_id(M::Interface, params, "interface_uuid", "interface_id") if params["interface_uuid"]
    }
  end

  get do
    get_all(:NetworkService, fill_options)
  end

  get '/:uuid' do
    get_by_uuid(:NetworkService, fill_options)
  end

  delete '/:uuid' do
    delete_by_uuid(:NetworkService)
  end

  put '/:uuid' do
    update_by_uuid(:NetworkService, put_post_shared_params, fill_options) { |params|
      check_syntax_and_get_id(M::Interface, params, "interface_uuid", "interface_id") if params["interface_uuid"]
    }
  end
end
