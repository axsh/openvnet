# -*- coding: utf-8 -*-

Vnmgr::Endpoints::VNetAPI.namespace '/mac_ranges' do
  post do
    mr_params = define_params(params,{
      :uuid => [String,nil],
      :range_begin => [Integer],
      :range_end => [Integer]
    })

    # Respond with new mac range
  end

  get do
    # Respons with all mac ranges
  end

  get '/:uuid' do
    mr_params = define_params(params,{:uuid => [String]})

    # Respond with single mac range
  end

  delete '/:uuid' do
    mr_params = define_params(params,{:uuid => [String]})

    # Respond with deleted mac range uuid
  end
end
