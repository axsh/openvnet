# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/dc_networks' do
  post do
    dcnw_params = define_params(params,{
      :uuid => [String,nil],
      :desciption => [String,nil]
    })

    # Respond with this dc_network
  end

  get do
    # Respond with all dc_networks
  end

  get '/:uuid' do
    dcnw_params = define_params(params,{:uuid => [String]})
    # Respond with a single dc_network
  end

  delete '/:uuid' do
    dcnw_params = define_params(params,{:uuid => [String]})
    # Delete a single dc_network

    # Respond with dc_network id
  end

  put '/:uuid' do
    # Get dc_network from dba
    dcnw_params = define_params(params,{
      :uuid => [String],
      :desciption => [String,nil]
    })

    # use these params to update the dc_network and send it back to dba for storage

    # Respond with the modified dc_network
  end
end
