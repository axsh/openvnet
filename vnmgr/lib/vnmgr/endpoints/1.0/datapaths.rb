# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/datapaths' do
  post do
    params = parse_params(@params, ["uuid","open_flow_controller_uuid","display_name","ipv4_address","is_connected","datapath_id","created_at","updated_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::Datapath[params["uuid"]].nil?
      params["uuid"] = M::Datapath.trim_uuid(params["uuid"])
    end
    datapath = data_access.datapath.create(params)
    respond_with(R::Datapath.generate(datapath))
  end

  get do
    datapaths = data_access.datapath.all
    respond_with(R::DatapathCollection.generate(datapaths))
  end

  get '/:uuid' do
    datapath = data_access.datapath[{:uuid => @params["uuid"]}]
    respond_with(R::Datapath.generate(datapath))
  end

  delete '/:uuid' do
    datapath = data_access.datapath.delete({:uuid => @params["uuid"]})
    respond_with(R::Datapath.generate(datapath))
  end

  put '/:uuid' do
    params = parse_params(@params, ["uuid","open_flow_controller_uuid","display_name","ipv4_address","is_connected","datapath_id","created_at","updated_at"])
    datapath = data_access.datapath.update(params)
    respond_with(R::Datapath.generate(datapath))
  end
end
