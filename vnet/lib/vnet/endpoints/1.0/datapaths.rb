# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/datapaths' do
  post do
    accepted_params = [
      "uuid",
      "display_name",
      "ipv4_address",
      "is_connected",
      "dpid",
      "dc_segment_id",
      "node_id"
    ]
    required_params = ["display_name", "dpid", "node_id"]
    post_new(:Datapath, accepted_params, required_params) { |params|
      params['ipv4_address'] = parse_ipv4(params['ipv4_address'])
    }
  end

  get do
    get_all(:Datapath)
  end

  get '/:uuid' do
    get_by_uuid(:Datapath)
  end

  delete '/:uuid' do
    delete_by_uuid(:Datapath)
  end

  put '/:uuid' do
    update_by_uuid(:Datapath, [
      "display_name",
      "ipv4_address",
      "is_connected",
      "dpid",
      "dc_segment_id",
      "node_id"
    ]) {
      params['ipv4_address'] = parse_ipv4(params['ipv4_address'])
    }
  end

  post '/:uuid/networks/:network_uuid' do
    params = parse_params(@params, ['uuid','network_uuid','broadcast_mac_addr'])
    check_required_params(params, ["broadcast_mac_addr", "network_uuid"])

    datapath = check_syntax_and_pop_uuid(M::Datapath, params)
    network = check_syntax_and_pop_uuid(M::Network, params, 'network_uuid')

    broadcast_mac_addr = parse_mac(params['broadcast_mac_addr'])
    if broadcast_mac_addr.nil?
      error_msg = "invalid broadcast_mac_addr: '#{params[broadcast_mac_addr]}'"
      raise(E::ArgumentError, error_msg)
    end

    M::DatapathNetwork.create({ :datapath_id => datapath.id,
                                :network_id => network.id,
                                :broadcast_mac_addr => broadcast_mac_addr,
                              })

    respond_with(R::Datapath.networks(datapath))
  end

  delete '/:uuid/networks/:network_uuid' do
    datapath = check_syntax_and_pop_uuid(M::Datapath, @params)
    network = check_syntax_and_pop_uuid(M::Network, @params, 'network_uuid')
    relations = M::DatapathNetwork.filter({ :datapath_id => datapath.id,
                                :network_id => network.id
                              })

    relations.each { |r| r.destroy }

    respond_with(R::Datapath.networks(datapath))
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
