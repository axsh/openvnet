# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/dc_networks' do
  post do
    possible_params = ["uuid","display_name","parent_id","created_at","updated_at"]
    params = @params.delete_if {|k,v| !possible_params.member?(k)}
    params.default = nil

    dc_network = sb.dc_network.create(params)
    respond_with(R::DcNetwork.generate(dc_network))
  end

  get do
    dc_networks = sb.dc_network.get_all
    respond_with(R::DcNetworkCollection.generate(dc_networks))
  end

  get '/:uuid' do
    dc_network = sb.dc_network.get(@params["uuid"])
    respond_with(R::DcNetwork.generate(dc_network))
  end

  delete '/:uuid' do
    sb.dc_network.delete(@params["uuid"])
    respond_with({:uuid => @params["uuid"]})
  end

  put '/:uuid' do
    new_params = filter_params(params)
    dc_network = sb.dc_network.update(new_params)
    respond_with(R::DcNetwork.generate(dc_network))
  end
end
