# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/datapaths' do
  post do
    dp_params = define_params(params,{
      :uuid => [String,nil],
      :ssl_settings => [nil], # Settings for the ssl connection between the datapath and the controller. Will probably be broken up into more parameters in the future.
      :controller_uuid => [String]
    })

    # Respond with this datapath
  end

  get do
    # Respond with all datapaths
  end

  get '/:uuid' do
    dp_params = define_params(params,{:uuid => [String]})
    # Respond with a single datapath
  end

  delete '/:uuid' do
    dp_params = define_params(params,{:uuid => [String]})
    # Delete a single datapath

    # Respond with datapath id
  end

  put '/:uuid' do
    # Get datapath from dba
    dp_params = define_params(params,{
      :uuid => [String],
      :ssl_settings => [nil], # Settings for the ssl connection between the datapath and the controller. Will probably be broken up into more parameters in the future.
      :controller_uuid => [String,nil]
    })

    # use these params to update the datapath and send it back to dba for storage

    # Respond with the modified datapath
  end
end
