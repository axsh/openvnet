# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/datapaths' do
  post do
    params = parse_params(@params, ["uuid","display_name","ipv4_address","is_connected","dpid","dc_segment_id","node_id"])
    required_params(params, ["display_name", "dpid", "node_id"])
    check_and_trim_uuid(M::Datapath, params) if params.has_key?("uuid")

    params['ipv4_address'] = parse_ipv4(params['ipv4_address'])

    datapath = M::Datapath.batch { |n| n.create(params) }
    respond_with(R::Datapath.generate(datapath))
  end

  get do
    datapaths = M::Datapath.all
    respond_with(R::DatapathCollection.generate(datapaths))
  end

  get '/:uuid' do
    datapath = check_syntax_and_pop_uuid(M::Datapath, @params)
    respond_with(R::Datapath.generate(datapath))
  end

  delete '/:uuid' do
    datapath = check_syntax_and_pop_uuid(M::Datapath, @params)
    datapath.batch.destroy.commit
    respond_with(R::Datapath.generate(datapath))
  end

  put '/:uuid' do
    params = parse_params(@params, ["uuid", "display_name", "ipv4_address",
      "is_connected", "dpid", "dc_segment_id", "node_id"])
    datapath = check_syntax_and_pop_uuid(M::Datapath, params)

    datapath.batch.update(params).commit
    updated_dp = M::Datapath[@params["uuid"]]
    respond_with(R::Datapath.generate(updated_dp))
  end

  #TODO: Add equivalent delete_network method
  post '/:uuid/network/:network_uuid' do
    params = parse_params(@params, ['uuid','network_uuid','broadcast_mac_address'])
    required_params(params, ["broadcast_mac_address", "network_uuid]")

    datapath = check_syntax_and_pop_uuid(M::Datapath, params)
    network = check_syntax_and_pop_uuid(M::Network, params, 'network_uuid')

    broadcast_mac_address = parse_mac(params['broadcast_mac_address'])
    if broadcast_mac_address.nil?
      error_msg = "invalid broadcast_mac_address: '#{params[broadcast_mac_address]}'"
      raise(E::ArgumentError, error_msg)
    end

    M::DatapathNetwork.create({ :datapath_id => datapath.id,
                                :network_id => network.id,
                                :broadcast_mac_addr => broadcast_mac_address,
                              })
    respond_with({})
  end

  put '/:uuid/route_links' do
    params = parse_params(@params, ['uuid', 'route_link_uuid', 'link_mac_address'])
    required_params(params, ['link_mac_address'])

    datapath = check_syntax_and_pop_uuid(M::Datapath, params)
    route_link = check_syntax_and_pop_uuid(M::RouteLink, params, 'route_link_uuid')

    link_mac_address = parse_mac(params['link_mac_address'])
    if link_mac_address.nil?
      error_msg = "invalid link_mac_address: '#{params['link_mac_address']}'"
      raise(E::ArgumentError, error_msg)
    end

    M::DatapathRouteLink.create({ :datapath_id => datapath.id,
                                  :route_link_id => route_link.id,
                                  :link_mac_addr => link_mac_address,
                                })
    respond_with({})
  end

end
