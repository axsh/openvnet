# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/datapaths' do
  def self.put_post_shared_params
    param :display_name, :String
    param :is_connected, :Boolean
    param :dpid, :String, transform: :hex
    param :node_id, :String
  end

  put_post_shared_params
  param_options :display_name, required: true
  param_options :dpid, required: true
  param_options :node_id, required: true
  param_uuid M::Datapath
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

  param :broadcast_mac_address, :String, required: true, transform: PARSE_MAC
  param_uuid M::Interface, :interface_uuid, required: true
  post '/:uuid/networks/:network_uuid' do
    datapath = check_syntax_and_pop_uuid(M::Datapath)
    interface = check_syntax_and_pop_uuid(M::Interface, 'interface_uuid')
    network = check_syntax_and_pop_uuid(M::Network, 'network_uuid')

    M::DatapathNetwork.create({ :datapath_id => datapath.id,
                                :interface_id => interface.id,
                                :network_id => network.id,
                                :broadcast_mac_address => params["broadcast_mac_address"]
                              })

    respond_with(R::Network.generate(network))
  end

  get '/:uuid/networks' do
    show_relations(:Datapath, :networks)
  end

  delete '/:uuid/networks/:network_uuid' do
    datapath = check_syntax_and_pop_uuid(M::Datapath)
    network = check_syntax_and_pop_uuid(M::Network, 'network_uuid')

    M::DatapathNetwork.destroy(
      :datapath_id => datapath.id,
      :network_id => network.id
    )

    respond_with([network.uuid])
  end

  param :mac_address, :String, required: true, transform: PARSE_MAC
  param_uuid M::Interface, :interface_uuid, required: true
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

    relations = M::DatapathRouteLink.filter({
      :datapath_id => datapath.id,
      :route_link_id => route_link.id
    })

    relations.each { |r| r.destroy }

    respond_with([route_link.uuid])
  end

end
