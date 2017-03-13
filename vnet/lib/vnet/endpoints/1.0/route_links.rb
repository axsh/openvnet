# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/route_links' do

  param_uuid M::RouteLink
  param_uuid M::Topology, :topology_uuid
  param :mac_address, :String, transform: PARSE_MAC
  post do
    uuid_to_id(M::Topology, 'topology_uuid', 'topology_id') if params['topology_uuid']

    post_new(:RouteLink)
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
