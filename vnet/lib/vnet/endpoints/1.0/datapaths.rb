# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/datapaths' do
  put_post_shared_params = [
    "display_name",
    "ipv4_address",
    "is_connected",
    "dpid",
    "dc_segment_uuid",
    "node_id"
  ]

  post do
    accepted_params = put_post_shared_params + ["uuid"]
    required_params = ["display_name", "dpid", "node_id"]

    post_new(:Datapath, accepted_params, required_params) { |params|
      params['ipv4_address'] = parse_ipv4(params['ipv4_address']) if params["ipv4_address"]
      # TODO Currently this doesn't work because there isn't the api for DcSegment. Write it if we really need Sequel model just to judge whether datapaths belong to same segment or not
      #check_syntax_and_get_id(M::DcSegment, params, "dc_segment_uuid", "dc_segment_id") if params["dc_segment_uuid"]
      if params["dc_segment_uuid"]
        dc_segment_uuid = params.delete("dc_segment_uuid")
        check_uuid_syntax(M::DcSegment, dc_segment_uuid)
        params["dc_segment_id"] = (M::DcSegment[dc_segment_uuid] || M::DcSegment.create(uuid: dc_segment_uuid)).id
      end
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
    update_by_uuid(:Datapath, put_post_shared_params) { |params|
      params['ipv4_address'] = parse_ipv4(params['ipv4_address']) if params['ipv4_address']
      check_syntax_and_get_id(M::DcSegment, params, "dc_segment_uuid", "dc_segment_id") if params["dc_segment_uuid"]
    }
  end

  post '/:uuid/networks/:network_uuid' do
    params = parse_params(@params, ['uuid','network_uuid','broadcast_mac_address'])
    check_required_params(params, ["broadcast_mac_address", "network_uuid"])

    datapath = check_syntax_and_pop_uuid(M::Datapath, params)
    network = check_syntax_and_pop_uuid(M::Network, params, 'network_uuid')

    broadcast_mac_address = parse_mac(params['broadcast_mac_address'])

    M::DatapathNetwork.create({ :datapath_id => datapath.id,
                                :network_id => network.id,
                                :broadcast_mac_address => broadcast_mac_address,
                              })

    respond_with(R::Datapath.networks(datapath))
  end

  get '/:uuid/networks' do
    show_relations(:Datapath, :networks)
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

  post '/:uuid/route_links/:route_link_uuid' do
    params = parse_params(@params, ['uuid', 'route_link_uuid', 'mac_address'])
    check_required_params(params, ['mac_address'])

    datapath = check_syntax_and_pop_uuid(M::Datapath, params)
    route_link = check_syntax_and_pop_uuid(M::RouteLink, params, 'route_link_uuid')
    mac_address = parse_mac(params['mac_address'])

    M::DatapathRouteLink.create({ :datapath_id => datapath.id,
                                  :route_link_id => route_link.id,
                                  :mac_address => mac_address,
                                })
    respond_with(R::Datapath.route_links(datapath))
  end

  get '/:uuid/route_links' do
    show_relations(:Datapath, :route_links)
  end

  delete '/:uuid/route_links/:route_link_uuid' do
    datapath = check_syntax_and_pop_uuid(M::Datapath, @params)
    route_link = check_syntax_and_pop_uuid(M::RouteLink, @params, 'route_link_uuid')
    relations = M::DatapathRouteLink.filter({ :datapath_id => datapath.id,
                                :route_link_id => route_link.id
                              })

    relations.each { |r| r.destroy }

    respond_with(R::Datapath.route_links(datapath))
  end

end
