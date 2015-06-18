# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/datapaths' do
  def self.put_post_shared_params
    param :display_name, :String
    param :is_connected, :Boolean
    param :dpid, :String, transform: :hex, format: /^(0x)?[0-9a-f]{0,16}$/i, on_error: proc { |error|
      if error[:reason] == :format
        raise E::ArgumentError, "dpid must be a 16 byte hexadecimal number. Got: \"#{error[:value]}\""
      else
        vnet_default_on_error(error)
      end
    }
    param :node_id, :String
  end

  put_post_shared_params
  param_uuid M::Datapath
  param_options :display_name, required: true
  param_options :dpid, required: true
  param_options :node_id, required: true
  post do
    post_new(:Datapath)
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

  put_post_shared_params
  put '/:uuid' do
    update_by_uuid(:Datapath)
  end

  param_uuid M::Datapath, :uuid, required: true
  param_uuid M::Network, :network_uuid, required: true
  param_uuid M::Interface, :interface_uuid, required: true
  param :broadcast_mac_address, :String, required: true, transform: PARSE_MAC
  post '/:uuid/networks/:network_uuid' do
    Vnet::NodeApi.datapath.associate_network(params["uuid"],
                                             params["network_uuid"],
                                             params["interface_uuid"],
                                             params["broadcast_mac_address"]
                                             )
    # TODO: use response from associate_network().
    network = check_syntax_and_pop_uuid(M::Network, 'network_uuid')
    respond_with(R::Network.generate(network))
  end

  get '/:uuid/networks' do
    show_relations(:Datapath, :networks)
  end

  delete '/:uuid/networks/:network_uuid' do
    datapath = check_syntax_and_pop_uuid(M::Datapath)
    network = check_syntax_and_pop_uuid(M::Network, 'network_uuid')

    M::DatapathNetwork.destroy(datapath_id: datapath.id, generic_id: network.id)

    respond_with([network.uuid])
  end

  param_uuid M::Interface, :interface_uuid, required: true
  param :mac_address, :String, required: true, transform: PARSE_MAC
  post '/:uuid/route_links/:route_link_uuid' do
    datapath = check_syntax_and_pop_uuid(M::Datapath)
    interface = check_syntax_and_pop_uuid(M::Interface, 'interface_uuid')
    route_link = check_syntax_and_pop_uuid(M::RouteLink, 'route_link_uuid')

    M::DatapathRouteLink.create({ :datapath_id => datapath.id,
                                  :interface_id => interface.id,
                                  :route_link_id => route_link.id,
                                  :mac_address => params["mac_address"],
                                })

    respond_with(R::RouteLink.generate(route_link))
  end

  get '/:uuid/route_links' do
    show_relations(:Datapath, :route_links)
  end

  delete '/:uuid/route_links/:route_link_uuid' do
    datapath = check_syntax_and_pop_uuid(M::Datapath)
    route_link = check_syntax_and_pop_uuid(M::RouteLink, 'route_link_uuid')

    M::DatapathRouteLink.destroy(datapath_id: datapath.id, generic_id: route_link.id)

    respond_with([route_link.uuid])
  end

end
