# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/route_links' do

  post do
    accepted_params = ['uuid', 'mac_address']
    required_params = ['mac_address']

    post_new(:RouteLink, accepted_params, required_params) { |params|
      params['mac_address'] = parse_mac(params['mac_address'])
    }
  end

  get do
    get_all(:RouteLink)
  end

  get '/:uuid' do
    get_by_uuid(:RouteLink)
  end

  delete '/:uuid' do
    delete_by_uuid(:RouteLink)
  end
end
