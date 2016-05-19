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

  param_uuid M::Interface, :interface_uuid, required: true
  param :mac_address, :String, required: false, transform: PARSE_MAC
  post '/:uuid/networks/:network_uuid' do
    network = check_syntax_and_pop_uuid(M::Network, 'network_uuid')

    options = {
      datapath_id: check_syntax_and_pop_uuid(M::Datapath).id,
      interface_id: check_syntax_and_pop_uuid(M::Interface, 'interface_uuid').id,
      network_id: network.id,
      mac_address: params["mac_address"]
    }

    object = M::DatapathNetwork.create(options)
    respond_with(R::DatapathNetwork.generate(object))
  end

  get '/:uuid/networks' do
    show_relations(:Datapath, :networks)
  end

  delete '/:uuid/networks/:network_uuid' do
    network = check_syntax_and_pop_uuid(M::Network, 'network_uuid')

    options = {
      datapath_id: check_syntax_and_pop_uuid(M::Datapath).id,
      generic_id: network.id,
    }

    M::DatapathNetwork.destroy(options)

    respond_with([network.uuid])
  end

  param_uuid M::Interface, :interface_uuid, required: true
  param :mac_address, :String, required: false, transform: PARSE_MAC
  post '/:uuid/segments/:segment_uuid' do
    segment = check_syntax_and_pop_uuid(M::Segment, 'segment_uuid')

    options = {
      datapath_id: check_syntax_and_pop_uuid(M::Datapath).id,
      interface_id: check_syntax_and_pop_uuid(M::Interface, 'interface_uuid').id,
      segment_id: segment.id,
      mac_address: params["mac_address"]
    }

    object = M::DatapathSegment.create(options)
    respond_with(R::DatapathSegment.generate(object))
  end

  get '/:uuid/segments' do
    show_relations(:Datapath, :segments)
  end

  delete '/:uuid/segments/:segment_uuid' do
    segment = check_syntax_and_pop_uuid(M::Segment, 'segment_uuid')

    options = {
      datapath_id: check_syntax_and_pop_uuid(M::Datapath).id,
      generic_id: segment.id,
    }

    M::DatapathSegment.destroy(options)

    respond_with([segment.uuid])
  end

  param_uuid M::Interface, :interface_uuid, required: true
  param :mac_address, :String, required: false, transform: PARSE_MAC
  post '/:uuid/route_links/:route_link_uuid' do
    route_link = check_syntax_and_pop_uuid(M::RouteLink, 'route_link_uuid')

    options = {
      datapath_id: check_syntax_and_pop_uuid(M::Datapath).id,
      interface_id: check_syntax_and_pop_uuid(M::Interface, 'interface_uuid').id,
      route_link_id: route_link.id,
      mac_address: params["mac_address"]
    }

    object = M::DatapathRouteLink.create(options)
    respond_with(R::DatapathRouteLink.generate(object))
  end

  get '/:uuid/route_links' do
    show_relations(:Datapath, :route_links)
  end

  delete '/:uuid/route_links/:route_link_uuid' do
    route_link = check_syntax_and_pop_uuid(M::RouteLink, 'route_link_uuid')

    options = {
      datapath_id: check_syntax_and_pop_uuid(M::Datapath).id,
      generic_id: route_link.id
    }

    M::DatapathRouteLink.destroy(options)

    # TODO: Change return type.
    respond_with([route_link.uuid])
  end

end
