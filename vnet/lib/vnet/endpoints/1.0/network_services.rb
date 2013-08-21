# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/network_services' do

  post do
    params = parse_params(@params, ["uuid","iface_uuid","display_name","incoming_port","outgoing_port","created_at","updated_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::NetworkService[params["uuid"]].nil?
      params["uuid"] = M::NetworkService.trim_uuid(params["uuid"])
    end

    iface_uuid = params.delete('iface_uuid')
    params['iface_id'] = (M::Iface[iface_uuid] || raise(E::InvalidUUID, iface_uuid)).id

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
    params = parse_params(@params, ["iface_uuid","display_name","incoming_port","outgoing_port","created_at","updated_at"])
    network_service = M::NetworkService.update(@params["uuid"], params)
    respond_with(R::NetworkService.generate(network_service))
  end
end
