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

  get '/:id' do
    # Respond with a single network
  end

  delete '/:id' do
    # Delete a single network

    # Respond with network id
  end

  put '/:id' do
    # Get network from dba
    new_nw_params = define_params(params,{:desciption => [String,nil]})

    #use these params to update the network and send it back to dba for storage

    # Respond with the modified network
  end
end
