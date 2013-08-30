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
    network_service = check_syntax_and_pop_uuid(M::NetworkService, @params)
    respond_with(R::NetworkService.generate(network_service))
  end

  delete '/:uuid' do
    delete_by_uuid(M::NetworkService)
  end

  put '/:uuid' do
    params = parse_params(@params, ["uuid", "vif_uuid", "display_name",
      "incoming_port", "outgoing_port"])
    network_service = check_syntax_and_pop_uuid(M::NetworkService, params)
    network_service.batch.update(params).commit
    updated_nws = M::NetworkService[@params["uuid"]]
    respond_with(R::NetworkService.generate(updated_nws))
  end
end
