# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/dc_networks' do
  post do
    params = parse_params(@params, ["uuid","display_name","parent_id","created_at","updated_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::DcNetwork[params["uuid"]].nil?
      params["uuid"] = M::DcNetwork.trim_uuid(params["uuid"])
    end
    dc_network = sb.dc_network.create(params)
    respond_with(R::DcNetwork.generate(dc_network))
  end

  get do
    dc_networks = sb.dc_network.all
    respond_with(R::DcNetworkCollection.generate(dc_networks))
  end

  get '/:uuid' do
    dc_network = sb.dc_network[{:uuid => @params["uuid"]}]
    respond_with(R::DcNetwork.generate(dc_network))
  end

  delete '/:uuid' do
    dc_network = sb.dc_network.delete({:uuid => @params["uuid"]})
    respond_with(R::DcNetwork.generate(dc_network))
  end

  put '/:uuid' do
    params = parse_params(@params, ["uuid","display_name","parent_id","created_at","updated_at"])
    dc_network = sb.dc_network.update(new_params)
    respond_with(R::DcNetwork.generate(dc_network))
  end
end
