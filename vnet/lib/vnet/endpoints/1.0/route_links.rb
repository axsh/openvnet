# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/route_links' do

  param_uuid M::RouteLink
  param_uuid M::Topology, :topology_uuid
  param :mac_address, :String, transform: PARSE_MAC
  param :mrg_uuid, :String
  param :mac_range_group_uuid, :String
  post do
    uuid_to_id(M::Topology, 'topology_uuid', 'topology_id') if params['topology_uuid']

    uuid_to_id(M::MacRangeGroup, 'mrg_uuid', 'mac_range_group_id') if params['mrg_uuid']
    uuid_to_id(M::MacRangeGroup, 'mac_range_group_uuid', 'mac_range_group_id') if params['mac_range_group_uuid']

    if params['mac_address'].nil? && params['mac_range_group_id'].nil? && params['topology_id'].nil?
      raise(E::MissingArgument, 'mac_address')
    end

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
