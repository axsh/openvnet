# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/network_services' do
  put_post_shared_params = [
    "vif_uuid",
    "display_name",
    "incoming_port",
    "outgoing_port"
  ]

  post do
    accepted_params = put_post_shared_params + ["uuid"]
    required_params = ["display_name"]

    post_new(:NetworkService, accepted_params, required_params) { |params|
      check_syntax_and_get_id(M::Interface, params, "vif_uuid", "interface_id") if params["vif_uuid"]
    }
  end

  get do
    get_all(:NetworkService)
  end

  get '/:uuid' do
    get_by_uuid(:NetworkService)
  end

  delete '/:uuid' do
    delete_by_uuid(:NetworkService)
  end

  put '/:uuid' do
    update_by_uuid(:NetworkService, put_post_shared_params) { |params|
      check_syntax_and_get_id(M::Interface, params, "vif_uuid", "interface_id") if params["vif_uuid"]
    }
  end
end
