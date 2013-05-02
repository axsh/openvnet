# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/dhcp' do
  post do
    dhcp_params = define_params(params,{
      :uuid => [String,nil],
      :network_uuid => [String]
    })

    # Respond with new dhcp service
  end

  get do
    # Respond with all dhcp services
  end

  get '/:uuid' do
    dhcp_params = define_params(params,{:uuid => [String]})

    # Respond with a single dhcp service
  end

  delete '/:uuid' do
    dhcp_params = define_params(params,{:uuid => [String]})

    # Respond with the deleted service's uuid
  end

  put '/:uuid' do
    dhcp_params = define_params(params,{:uuid => [String]})

    # Respond with the updated dhcp service
  end
end
