# -*- coding: utf-8 -*-

Vnmgr::Endpoints::VNetAPI.namespace '/vifs' do

  post do
    vif_params = define_params(params,{
      :uuid => [String,nil],
      :mac_addr => [Int]
    })

    # Respond with new vif
  end

  get do
    # Respond with all vifs
  end

  get '/:uuid' do
    vif_params = define_params(params,{:uuid => [String]})

    # Respond with one vif
  end

  delete '/:uuid' do
    vif_params = define_params(params,{:uuid => [String]})

    # Respond with deletd vif uuid
  end

end
