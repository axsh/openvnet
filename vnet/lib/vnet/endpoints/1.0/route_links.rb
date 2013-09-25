# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/route_links' do

  post do
    accepted_params = ['uuid', 'mac_address_uuid']
    required_params = ['mac_address_uuid']

    post_new(:RouteLink, accepted_params, required_params) { |params|
      check_syntax_and_get_id(M::MacAddress, params, "mac_address_uuid", "mac_address_id") if params["mac_address_uuid"]
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

  put '/:uuid' do
    params = parse_params(@params, [])
    params['mac_address_id'] = pop_uuid(M::MacAddress, params, 'mac_address_uuid').id if params.has_key?('mac_address_uuid')
    route_link = M::RouteLink.update(@params['uuid'], params)
    respond_with(R::RouteLink.generate(route_link))
  end
end
