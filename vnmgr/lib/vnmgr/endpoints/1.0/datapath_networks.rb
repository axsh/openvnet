# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/datapath_networks' do
  post do
    params = parse_params(@params, ["uuid","datapath_id","network_id","broadcast_mac_addr","is_connected","created_at","updated_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::DatapathNetwork[params["uuid"]].nil?
      params["uuid"] = M::DatapathNetwork.trim_uuid(params["uuid"])
    end
    datapath = M::DatapathNetwork.create(params)
    respond_with(R::DatapathNetwork.generate(datapath))
  end

  get do
    datapaths = M::DatapathNetwork.all
    respond_with(R::DatapathNetworkCollection.generate(datapaths))
  end

  get '/:uuid' do
    datapath = M::DatapathNetwork[@params["uuid"]]
    respond_with(R::DatapathNetwork.generate(datapath))
  end

  delete '/:uuid' do
    datapath = M::DatapathNetwork.destroy(@params["uuid"])
    respond_with(R::DatapathNetwork.generate(datapath))
  end

  put '/:uuid' do
    params = parse_params(@params, ["datapath_id","network_id","broadcast_mac_addr","is_connected","created_at","updated_at"])
    datapath = M::DatapathNetwork.update(@params["uuid"], params)
    respond_with(R::DatapathNetwork.generate(datapath))
  end
end
