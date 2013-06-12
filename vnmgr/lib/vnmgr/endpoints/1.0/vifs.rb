# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/vifs' do

  post do
    params = parse_params(@params, ["uuid","network_id","mac_addr","state","created_at","updated_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::Vif[params["uuid"]].nil?
      params["uuid"] = M::Vif.trim_uuid(params["uuid"])
    end
    vif = M::Vif.create(params)
    respond_with(R::Vif.generate(vif))
  end

  get do
    vifs = M::Vif.all
    respond_with(R::VifCollection.generate(vifs))
  end

  get '/:uuid' do
    vif = M::Vif[@params["uuid"]]
    respond_with(R::Vif.generate(vif))
  end

  delete '/:uuid' do
    vif = M::Vif.delete({:uuid => @params["uuid"]})
    respond_with(R::Vif.generate(vif))
  end

  put '/:uuid' do
    params = parse_params(@params, ["network_id","mac_addr","state","created_at","updated_at"])
    vif = M::Vif.update(params)
    respond_with(R::Vif.generate(vif))
  end
end
