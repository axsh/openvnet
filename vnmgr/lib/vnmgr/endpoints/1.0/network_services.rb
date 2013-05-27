# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/network_services' do

  post do
    params = parse_params(@params, ["uuid","vif_uuid","display_name","incoming_port","outgoing_port","created_at","updated_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::NetworkService[params["uuid"]].nil?
      params["uuid"] = M::NetworkService.trim_uuid(params["uuid"])
    end
    network_service = sb.network_service.create(params)
    respond_with(R::NetworkService.generate(network_service))
  end

  get do
    network_services = sb.network_service.all
    respond_with(R::NetworkServiceCollection.generate(network_services))
  end

  get '/:uuid' do
    network_service = sb.network_service[{:uuid => @params["uuid"]}]
    respond_with(R::NetworkService.generate(network_service))
  end

  delete '/:uuid' do
    network_service = sb.network_service.delete({:uuid => @params["uuid"]})
    respond_with(R::NetworkService.generate(network_service))
  end

  put '/:uuid' do
    params = parse_params(@params, ["uuid","vif_uuid","display_name","incoming_port","outgoing_port","created_at","updated_at"])
    network_service = sb.network_service.update(params)
    respond_with(R::NetworkService.generate(network_service))
  end
end
