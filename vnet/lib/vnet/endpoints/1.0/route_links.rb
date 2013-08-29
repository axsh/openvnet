# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/route_links' do

  post do
    params = parse_params(@params, ['uuid', 'mac_address'])

    if params.has_key?('uuid')
      raise E::DuplicateUUID, params['uuid'] unless M::RouteLink[params['uuid']].nil?
      params['uuid'] = M::RouteLink.trim_uuid(params['uuid'])
    end

    params['mac_address'] = parse_mac(params['mac_address']) || raise(E::MissingArgument, 'mac_address')

    route_link = M::RouteLink.create(params)
    respond_with(R::RouteLink.generate(route_link))
  end

  get do
    route_links = M::RouteLink.all
    respond_with(R::RouteLinkCollection.generate(route_links))
  end

  get '/:uuid' do
    route_link = M::RouteLink[@params['uuid']]
    respond_with(R::RouteLink.generate(route_link))
  end

  delete '/:uuid' do
    route_link = M::RouteLink.destroy(@params['uuid'])
    respond_with(R::RouteLink.generate(route_link))
  end
end
