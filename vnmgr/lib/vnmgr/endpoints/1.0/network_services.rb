# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/network_services' do

  post do
    params = parse_params(@params, ["uuid","vif_uuid","display_name","incoming_port","outgoing_port","created_at","updated_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::NetworkService[params["uuid"]].nil?
      params["uuid"] = M::NetworkService.trim_uuid(params["uuid"])
    end

    vif_uuid = params.delete('vif_uuid')
    params['vif_id'] = (M::Vif[vif_uuid] || raise(E::InvalidUUID, vif_uuid)).id

    network_service = M::NetworkService.create(params)
    respond_with(R::NetworkService.generate(network_service))
  end

  get do
    network_services = M::NetworkService.all
    respond_with(R::NetworkServiceCollection.generate(network_services))
  end

  get '/:uuid' do
    network_service = M::NetworkService[@params["uuid"]]
    respond_with(R::NetworkService.generate(network_service))
  end

  delete '/:uuid' do
    network_service = M::NetworkService.destroy(@params["uuid"])
    respond_with(R::NetworkService.generate(network_service))
  end

  put '/:uuid' do
    params = parse_params(@params, ["vif_uuid","display_name","incoming_port","outgoing_port","created_at","updated_at"])
    network_service = M::NetworkService.update(@params["uuid"], params)
    respond_with(R::NetworkService.generate(network_service))
  end
end
