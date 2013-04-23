# -*- coding: utf-8 -*-

Vnmgr::Endpoints::VNetAPI.namespace '/networks' do
  post do
    new_nw_params = define_params(params,{
      :ivp4_network => [Integer],
      :prefix => [Integer],
      :uuid => [String,nil],
      :desciption => [String,nil]
    })

    # Respond with this network
  end

  get do
    # Respond with all networks
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
