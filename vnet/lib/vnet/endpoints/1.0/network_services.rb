# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/network_services' do

  post do
    params = parse_params(@params, ["uuid", "vif_uuid", "display_name",
      "incoming_port", "outgoing_port"])
    required_params(params, ["display_name"])
    check_and_trim_uuid(M::NetworkService, params) if params["uuid"]
    check_syntax_and_get_id(M::Vif, params, "vif_uuid", "vif_id") if params["vif_uuid"]

    network_service = M::NetworkService.create(params)
    respond_with(R::NetworkService.generate(network_service))
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
    update_by_uuid(:NetworkService, [
      "vif_uuid",
      "display_name",
      "incoming_port",
      "outgoing_port"
    ])
  end
end
