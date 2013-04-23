# -*- coding: utf-8 -*-

Vnmgr::Endpoints::VNetAPI.namespace '/dns' do
  post do
    dns_params = define_params(params,{
      :uuid => [String,nil]
    })

    # Respond with new dns service
  end

  get do
    # Respond with all dns services
  end

  get '/:uuid' do
    dns_params = define_params(params,{:uuid => [String]})

    # Respond with a single dns service
  end

  delete '/:uuid' do
    dns_params = define_params(params,{:uuid => [String]})

    # Respond with the deleted service's uuid
  end

  put '/:uuid' do
    dns_params = define_params(params,{:uuid => [String]})

    # Respond with the updated dns service
  end
end
