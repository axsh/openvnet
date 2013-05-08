# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/networks' do
  post do
    # Respond with this network
  end

  get do
    # networks = SB.network.all
    dba_node = DCell::Node["vnmgr"]
    networks = dba_node[:db_agent].get_all(:Network)

    respond_with(R::NetworkCollection.generate(networks))
  end

  get '/:uuid' do
    # Respond with a single network
  end

  delete '/:uuid' do
    # Delete a single network

    # Respond with network id
  end

  put '/:uuid' do
    # Get network from dba
    new_nw_params = define_params(params,{:desciption => [String,nil]})

    #use these params to update the network and send it back to dba for storage

    # Respond with the modified network
  end

  put '/:uuid/attach_vif' do
    av_params = define_params(params,{
      :uuid => [String],
      :vif_uuid => [String],
      :ipv4 => [Int,nil]
    })

    # Respond with network
  end

  put '/:uuid/detach_vif' do
    av_params = define_params(params,{
      :vif_uuid => [String],
    })

    # Respond with network
  end
end
