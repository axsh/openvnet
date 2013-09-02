# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/network_services' do

  post do
    accepted_params = [
      "uuid",
      "vif_uuid",
      "display_name",
      "incoming_port",
      "outgoing_port"
    ]
    required_params = ["display_name"]

    post_new(:NetworkService, accepted_params, required_params) { |params|
      check_syntax_and_get_id(M::Vif, params, "vif_uuid", "vif_id") if params["vif_uuid"]
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
    accepted_params = [
      "vif_uuid",
      "display_name",
      "incoming_port",
      "outgoing_port"
    ]

    update_by_uuid(:NetworkService, accepted_params) { |params|
      check_syntax_and_get_id(M::Vif, params, "vif_uuid", "vif_id") if params["vif_uuid"]
    }
  end
end
