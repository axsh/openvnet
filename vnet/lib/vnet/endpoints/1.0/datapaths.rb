# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/datapaths' do
  post do
    params = parse_params(@params, ["uuid","open_flow_controller_uuid","display_name","ipv4_address","is_connected","dpid","dc_segment_id","node_id","created_at","updated_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::Datapath[params["uuid"]].nil?
      params["uuid"] = M::Datapath.trim_uuid(params["uuid"])
    end

    params['ipv4_address'] = parse_ipv4(params['ipv4_address'])

    datapath = M::Datapath.create(params)
    respond_with(R::Datapath.generate(datapath))
  end

  get do
    datapaths = M::Datapath.all
    respond_with(R::DatapathCollection.generate(datapaths))
  end

  get '/:uuid' do
    datapath = M::Datapath[@params["uuid"]]
    respond_with(R::Datapath.generate(datapath))
  end

  delete '/:uuid' do
    datapath = M::Datapath.destroy(@params["uuid"])
    respond_with(R::Datapath.generate(datapath))
  end

  put '/:uuid' do
    params = parse_params(@params, ["open_flow_controller_uuid","display_name","ipv4_address","is_connected","dpid","dc_segment_id","node_id","created_at","updated_at"])
    datapath = M::Datapath.update(@params["uuid"], params)
    respond_with(R::Datapath.generate(datapath))
  end

  put '/:uuid/networks' do
    params = parse_params(@params, ['uuid','network_uuid','broadcast_mac_address'])

    datapath = M::Datapath[params['uuid']] || raise(E::UnknownUUIDResource, params['uuid'])
    network = M::Network[params['network_uuid']] || raise(E::UnknownUUIDResource, params['network_uuid'])

    broadcast_mac_address = parse_mac(params['broadcast_mac_address']) || raise(E::MissingArgument, 'broadcast_mac_address')

    M::DatapathNetwork.create({ :datapath_id => datapath.id,
                                :network_id => network.id,
                                :broadcast_mac_addr => broadcast_mac_address,
                              })
    respond_with({})
  end

  put '/:uuid/route_links' do
    params = parse_params(@params, ['uuid','route_link_uuid','link_mac_address'])

    datapath = M::Datapath[params['uuid']] || raise(E::UnknownUUIDResource, params['uuid'])
    route_link = M::RouteLink[params['route_link_uuid']] || raise(E::UnknownUUIDResource, params['route_link_uuid'])

    link_mac_address = parse_mac(params['link_mac_address']) || raise(E::MissingArgument, 'link_mac_address')

    M::DatapathRouteLink.create({ :datapath_id => datapath.id,
                                  :route_link_id => route_link.id,
                                  :link_mac_addr => link_mac_address,
                                })
    respond_with({})
  end

end
